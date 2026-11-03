"""Catch missing skill resources, escaping aliases, and stale package records."""
from pathlib import Path
import json
import os
import runpy
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts/skills-inventory.py"
API = runpy.run_path(str(SCRIPT))


class SkillsInventoryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name) / "checkout"
        self.source = self.root / "shared/skills/example"
        self.source.mkdir(parents=True)
        (self.source / "SKILL.md").write_text("---\nname: example\ndescription: Check an example.\n---\n\n[Reference](references/usage.md)\n")
        (self.source / "references").mkdir()
        (self.source / "references/usage.md").write_text("Read the source.\n")
        (self.source / "LICENSE").write_text("Example license preserved by this test.\n")
        for tool in ("claude", "codex"):
            alias = self.root / tool / "skills/example"
            alias.parent.mkdir(parents=True)
            alias.symlink_to("../../shared/skills/example")
        self.refresh()

    def run_cli(self, *arguments):
        return subprocess.run([sys.executable, "-B", str(SCRIPT), "--repo", str(self.root), *arguments],
                              capture_output=True, text=True, timeout=10)

    def refresh(self):
        result = self.run_cli("--refresh")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_relocated_checkout_retains_aliases_and_digests(self):
        moved = self.root.parent / "relocated checkout"
        self.root.rename(moved)
        self.root = moved
        result = self.run_cli("--check")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["source_packages"], 1)

    def test_nested_resource_change_invalidates_manifest(self):
        (self.source / "references/usage.md").write_text("Changed source.\n")
        result = self.run_cli("--check")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("manifest differs", result.stderr)

    def test_missing_resource_is_rejected_even_during_refresh(self):
        (self.source / "references/usage.md").unlink()
        result = self.run_cli("--refresh")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Missing or external skill reference", result.stderr)

    def test_absolute_binding_is_rejected(self):
        alias = self.root / "codex/skills/example"
        alias.unlink()
        alias.symlink_to(self.source)
        result = self.run_cli("--check")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("relative repository alias", result.stderr)

    def test_license_removal_cannot_be_normalized_by_refresh(self):
        (self.source / "LICENSE").unlink()
        result = self.run_cli("--refresh")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Preserved notice changed or missing", result.stderr)

    def test_installed_comparison_accounts_for_external_tools_without_writes(self):
        install = self.root.parent / "installed"
        install.mkdir()
        (install / "example").symlink_to(self.source)
        (install / "external-tool").mkdir()
        manifest = json.loads((self.root / "skills-manifest.json").read_text())
        manifest["external_skills"] = [{"id": "external-tool"}]
        before = os.readlink(install / "example")
        report = API["compare_installed"](self.root, manifest, {"claude": install, "codex": install})
        self.assertEqual(report["claude"]["missing_from_repository"], [])
        self.assertEqual(report["claude"]["external_only"], ["external-tool"])
        self.assertEqual(os.readlink(install / "example"), before)


if __name__ == "__main__":
    unittest.main()
