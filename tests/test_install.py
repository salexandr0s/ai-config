"""Install an archived checkout into disposable homes, without native services."""

import io
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tarfile
import tempfile
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).split(b"\0")
        buffer = io.BytesIO()
        with tarfile.open(fileobj=buffer, mode="w") as archive:
            for entry in tracked:
                if not entry:
                    continue
                relative = os.fsdecode(entry)
                path = ROOT / relative
                if path.exists() or path.is_symlink():
                    archive.add(path, arcname=relative, recursive=False)
        cls.archive = buffer.getvalue()

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.config_home = self.home / "custom config & data"
        self.repo = self.root / "relocated checkout"
        self.repo.mkdir()
        with tarfile.open(fileobj=io.BytesIO(self.archive)) as archive:
            archive.extractall(self.repo)
        self.bin = self.root / "fake bin"
        self.bin.mkdir()
        self.stub("bun", 'printf "bun\\n" >> "$HOME/service-calls"\nexit 91\n')
        self.stub("launchctl", 'printf "launchctl %s\\n" "$*" >> "$HOME/service-calls"\n')
        self.env = {
            **os.environ, "HOME": str(self.home), "XDG_CONFIG_HOME": str(self.config_home),
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "AI_HOOK_VERSION_CHECK": "0",
        }

    def stub(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + body)
        path.chmod(0o755)

    def install(self, *args):
        return subprocess.run(
            [str(self.repo / "install.sh"), *args], cwd=self.home, env=self.env,
            text=True, capture_output=True, timeout=30,
        )

    def assert_installed(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.config_home / "ai-config/repo").samefile(self.repo))
        self.assertTrue((self.home / ".codex/workflows").samefile(self.repo / "codex/workflows"))
        return tomllib.loads((self.home / ".codex/config.toml").read_text())

    def backup_roots(self):
        return list((self.config_home / "ai-config/backups").glob("*"))

    def test_relocated_install_repairs_links_and_preserves_private_content_on_repeat(self):
        workspace = self.home / "workspace with spaces"
        workspace.mkdir()
        (workspace / "AGENTS.md").symlink_to("missing-rules.md")
        overlay = self.home / ".claude/settings.local.json"
        overlay.parent.mkdir()
        overlay.write_text('{"outputStyle":"Private style"}\n')
        user = self.home / ".claude/USER"
        user.mkdir()
        (user / "MISSION.md").write_text("Keep private user context.\n")
        local = self.config_home / "codex/config.local.toml"
        local.parent.mkdir(parents=True)
        local.write_text('model = "private-local-model"\n')
        config = self.assert_installed(self.install("--workspace", "workspace with spaces"))
        self.assertEqual(config["model"], "private-local-model")
        self.assertTrue((workspace / "AGENTS.md").samefile(self.repo / "shared/CLAUDE.md"))
        self.assertFalse(user.is_symlink())
        self.assertEqual((user / "MISSION.md").read_text(), "Keep private user context.\n")
        self.assertEqual(overlay.read_text(), '{"outputStyle":"Private style"}\n')
        self.assertTrue((user / "GOALS.md").is_file())
        before = self.backup_roots()
        self.assert_installed(self.install("--skip-browse", "--skip-launchagent",
                                           "--workspace", "workspace with spaces"))
        self.assertEqual(self.backup_roots(), before)
        self.assertFalse((self.home / "service-calls").exists())
        settings = json.loads((self.home / ".claude/settings.json").read_text())
        hook = settings["hooks"]["PreToolUse"][0]["hooks"][0]["command"]
        result = subprocess.run(
            ["bash", "-c", hook], env=self.env,
            input=json.dumps({"tool_input": {"command": "echo fixture"}}),
            text=True, capture_output=True, timeout=5,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_checkout_at_managed_alias_is_not_moved_or_linked_to_itself(self):
        alias = self.config_home / "ai-config/repo"
        alias.parent.mkdir(parents=True)
        shutil.move(self.repo, alias)
        self.repo = alias
        self.assert_installed(self.install())
        self.assertFalse(alias.is_symlink())
        self.assertTrue((alias / "install.sh").is_file())
        self.assertEqual(self.backup_roots(), [])

    def test_prerequisite_and_empty_workspace_fail_before_moving_user_files(self):
        agents = self.home / ".claude/agents"
        agents.parent.mkdir()
        agents.write_text("Existing user file.\n")
        self.stub("python3", "exit 1\n")
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Python 3.11", result.stderr)
        self.assertEqual(agents.read_text(), "Existing user file.\n")
        self.assertFalse((self.config_home / "ai-config/repo").exists())
        self.assertEqual(self.backup_roots(), [])
        result = self.install("--workspace", "")
        self.assertEqual(result.returncode, 2)
        self.assertIn("requires a directory", result.stderr)

    def test_rapid_backups_use_distinct_roots_without_losing_earlier_files(self):
        self.stub("date", "printf '20260101000000\\n'\n")
        agents = self.home / ".claude/agents"
        agents.parent.mkdir()
        agents.write_text("First preserved file.\n")
        self.assert_installed(self.install())
        first = self.backup_roots()
        self.assertEqual(len(first), 1)
        agents.unlink()
        agents.write_text("Second preserved file.\n")
        self.assert_installed(self.install())
        roots = self.backup_roots()
        self.assertEqual(len(roots), 2)
        self.assertEqual({(path / "home/.claude/agents").read_text() for path in roots},
                         {"First preserved file.\n", "Second preserved file.\n"})

    def test_optional_launchagent_uses_absolute_alias_and_private_logs(self):
        self.stub("uname", "printf 'Darwin\\n'\n")
        self.assert_installed(self.install("--with-launchagent"))
        path = self.home / "Library/LaunchAgents/com.ai-config.memory-rotate.plist"
        with path.open("rb") as source:
            job = plistlib.load(source)
        self.assertEqual(job["ProgramArguments"], [
            "/bin/bash", str(self.config_home / "ai-config/repo/scripts/memory-rotate.sh")
        ])
        self.assertEqual(job["StandardOutPath"], str(self.home / ".cache/ai-config/memory-rotate.log"))
        self.assertEqual(job["StandardErrorPath"], job["StandardOutPath"])
        self.assertEqual(len((self.home / "service-calls").read_text().splitlines()), 2)

    def test_existing_user_context_symlink_is_not_written_through(self):
        target = self.root / "existing private context"
        target.mkdir()
        (target / "MISSION.md").write_text("Private context.\n")
        user = self.home / ".claude/USER"
        user.parent.mkdir()
        user.symlink_to(target, target_is_directory=True)
        self.assert_installed(self.install())
        self.assertTrue(user.is_symlink())
        self.assertEqual(sorted(path.name for path in target.iterdir()), ["MISSION.md"])
        self.assertEqual((target / "MISSION.md").read_text(), "Private context.\n")


if __name__ == "__main__":
    unittest.main()
