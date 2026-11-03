"""Regression coverage for private overlays and config replacement failures."""

import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("renderer", ROOT / "scripts/render-codex-config.py")
RENDERER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RENDERER)


class CodexConfigTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name) / "home with spaces"
        self.config_home = self.home / "custom config"
        self.local = self.config_home / "codex/config.local.toml"
        self.target = self.home / ".codex/config.toml"
        self.local.parent.mkdir(parents=True)
        self.target.parent.mkdir(parents=True)

    def run_renderer(self):
        return subprocess.run(
            [str(ROOT / "scripts/render-codex-config.sh")],
            env={**os.environ, "HOME": str(self.home), "XDG_CONFIG_HOME": str(self.config_home)},
            capture_output=True, text=True, timeout=10,
        )

    def test_root_tables_and_arrays_override_without_losing_native_or_unmanaged_state(self):
        self.target.write_text('''
model = "old-base-value"
custom_value = "retain me"
custom_control = "\\u007f"
[features]
custom_native_option = true
[projects."/workspace/other"]
trust_level = "trusted"
[plugins."example@market"]
enabled = true
[marketplaces.example]
source = { kind = "git", url = "https://example.com/catalog.git" }
[[marketplaces.example.entries]]
name = "first"
''')
        self.local.write_text('''
model = "local-model"
[tui]
notifications = true
[projects."/workspace/new project"]
trust_level = "untrusted"
[[skills.config]]
path = "/workspace/a/SKILL.md"
enabled = false
[plugins."example@market"]
enabled = false
''')
        first = self.run_renderer()
        self.assertEqual(first.returncode, 0, first.stderr)
        config = tomllib.loads(self.target.read_text())
        self.assertEqual(config["model"], "local-model")
        self.assertNotIn("model", config["profiles"]["review"])
        self.assertTrue(config["tui"]["notifications"])
        self.assertIn("status_line", config["tui"])
        self.assertEqual(config["custom_value"], "retain me")
        self.assertEqual(config["custom_control"], "\x7f")
        self.assertTrue(config["features"]["custom_native_option"])
        self.assertEqual(config["projects"]["/workspace/other"]["trust_level"], "trusted")
        self.assertEqual(config["projects"]["/workspace/new project"]["trust_level"], "untrusted")
        self.assertFalse(config["skills"]["config"][0]["enabled"])
        self.assertFalse(config["plugins"]["example@market"]["enabled"])
        self.assertEqual(config["marketplaces"]["example"]["entries"], [{"name": "first"}])
        self.assertEqual(self.target.stat().st_mode & 0o777, 0o600)
        before = self.target.read_bytes()
        second = self.run_renderer()
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(self.target.read_bytes(), before)

    def test_invalid_overlay_and_failed_atomic_replace_leave_previous_bytes_intact(self):
        before = b'model = "previous-valid"\n'
        self.target.write_bytes(before)
        self.local.write_text("[tui\nnotifications = true\n")
        result = self.run_renderer()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.target.read_bytes(), before)
        self.local.write_text('model = "new-value"\n')
        with patch.object(RENDERER.os, "replace", side_effect=PermissionError("fixture rename denied")):
            with self.assertRaises(PermissionError):
                RENDERER.render(ROOT, self.home, self.config_home)
        self.assertEqual(self.target.read_bytes(), before)
        self.assertEqual(list(self.target.parent.glob(".config-*.toml")), [])


if __name__ == "__main__":
    unittest.main()
