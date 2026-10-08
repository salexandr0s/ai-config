"""Exercise bundle damage and relocation using disposable ai-config fixtures."""

from pathlib import Path
import os
import runpy
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts/verify-avoid-ai-writing.py"
verification = runpy.run_path(str(SCRIPT))
PACKAGE_PATH = verification["PACKAGE_PATH"]
VerificationError = verification["VerificationError"]


class AvoidAIWritingPackageTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name).resolve()
        self.repo = self.base / "checkout"
        shutil.copytree(REPO / PACKAGE_PATH, self.repo / PACKAGE_PATH)
        for tool in ("claude", "codex"):
            alias = self.repo / tool / "skills/avoid-ai-writing"
            alias.parent.mkdir(parents=True)
            alias.symlink_to(os.readlink(REPO / tool / "skills/avoid-ai-writing"))

    def check(self):
        return verification["check_package"](self.repo)

    def run_helper(self, *arguments):
        return subprocess.run(
            [sys.executable, "-B", str(SCRIPT), "--repo", str(self.repo), *arguments],
            capture_output=True, text=True, timeout=60, check=False,
        )

    def snapshot(self):
        return {
            str(path.relative_to(self.repo)):
            (os.readlink(path) if path.is_symlink() else path.read_bytes())
            for path in self.repo.rglob("*") if path.is_symlink() or path.is_file()
        }

    def test_relative_aliases_survive_checkout_relocation(self):
        relocated = self.base / "renamed checkout"
        self.repo.rename(relocated)
        self.repo = relocated
        self.assertEqual(self.check(), relocated / PACKAGE_PATH)

    def test_broken_alias_is_rejected(self):
        alias = self.repo / "codex/skills/avoid-ai-writing"
        alias.unlink()
        alias.symlink_to("../../shared/skills/missing")
        with self.assertRaisesRegex(VerificationError, "broken alias"):
            self.check()

    def test_absolute_repository_alias_is_rejected(self):
        alias = self.repo / "claude/skills/avoid-ai-writing"
        alias.unlink()
        alias.symlink_to(self.repo / PACKAGE_PATH)
        with self.assertRaisesRegex(VerificationError, "alias must be relative"):
            self.check()

    def test_duplicate_directory_in_place_of_alias_is_rejected(self):
        alias = self.repo / "claude/skills/avoid-ai-writing"
        alias.unlink()
        shutil.copytree(self.repo / PACKAGE_PATH, alias)
        with self.assertRaisesRegex(VerificationError, "expected a symlink"):
            self.check()

    def test_missing_headline_reference_is_rejected(self):
        (self.repo / PACKAGE_PATH / "references/headlines.md").unlink()
        with self.assertRaisesRegex(VerificationError, "missing required bundle file"):
            self.check()

    def test_altered_attribution_notice_is_rejected(self):
        notice = self.repo / PACKAGE_PATH / "NOTICE.md"
        notice.write_bytes(notice.read_bytes() + b"\nUnreviewed attribution change.\n")
        with self.assertRaisesRegex(VerificationError, "immutable notice/license hash mismatch"):
            self.check()

    @unittest.skipUnless(shutil.which("node"), "Node is required for runtime checks")
    def test_verification_leaves_relocated_package_unchanged(self):
        relocated = self.base / "relocated checkout"
        self.repo.rename(relocated)
        self.repo = relocated
        before = self.snapshot()
        result = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.snapshot(), before)

    @unittest.skipUnless(shutil.which("node"), "Node is required for runtime checks")
    def test_explicit_installed_links_resolve_through_tool_aliases(self):
        links = []
        for tool in ("claude", "codex"):
            link = self.base / f"installed-{tool}"
            link.symlink_to(self.repo / tool / "skills/avoid-ai-writing")
            links.append(link)
        result = self.run_helper("--check-installed", "--claude-link", str(links[0]),
                                 "--codex-link", str(links[1]))
        self.assertEqual(result.returncode, 0, result.stderr)
        for link in links:
            self.assertIn(str(link), result.stdout)

    @unittest.skipUnless(shutil.which("node"), "Node is required for runtime checks")
    def test_native_regression_failure_is_visible(self):
        tests = self.repo / "tests"
        tests.mkdir()
        (tests / "avoid-ai-writing-tools.test.js").write_text(
            "const test = require('node:test');\n"
            "const assert = require('node:assert/strict');\n"
            "test('deliberate regression failure', () => assert.fail('must be visible'));\n",
            encoding="utf-8",
        )
        result = self.run_helper()
        self.assertEqual(result.returncode, 1)
        self.assertIn("deliberate regression failure", result.stderr)
        self.assertIn("must be visible", result.stderr)


if __name__ == "__main__":
    unittest.main()
