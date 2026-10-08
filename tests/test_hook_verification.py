"""End-to-end hook checks use disposable repositories and local fake tools."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "hook-verification.py"
spec = importlib.util.spec_from_file_location("hook_verification", SCRIPT)
verification = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verification)


class HookVerificationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.repo = self.base / "repo"
        self.repo.mkdir()
        self.bin = self.base / "bin"
        self.bin.mkdir()
        self.log = self.base / "checks.log"
        self.env = dict(os.environ, XDG_CACHE_HOME=str(self.base / "cache"),
                        PATH=f"{self.bin}:/usr/bin:/bin", CHECK_LOG=str(self.log))
        self.git("init", "-q")
        self.write("package.json", json.dumps({"scripts": {"verify:quick": "check"}}))
        self.write("main.ts", "const value = 1;\n")
        self.git("add", ".")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "baseline")
        self.fake_tool("npm", 'printf "%s\\n" "$PWD:$*" >> "$CHECK_LOG"\n')
        self.payload = {"session_id": "test-session", "cwd": str(self.repo),
                        "tool_name": "Bash", "tool_input": {"command": "true"},
                        "tool_use_id": "tool-1"}

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.repo), *args], env=self.env,
                              check=True, capture_output=True, text=True)

    def write(self, name, content):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def fake_tool(self, name, content):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + content)
        path.chmod(0o755)

    def hook(self, event, payload=None, agent="claude"):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--agent", agent, event],
            input=json.dumps(payload or self.payload), capture_output=True,
            text=True, env=self.env, timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def change(self, name="main.ts", content="const value = 2;\n", payload=None):
        self.hook("pre", payload)
        self.write(name, content)
        self.hook("post", payload)

    def test_read_only_tool_ignores_existing_user_edits(self):
        self.write("main.ts", "const userValue = 9;\n")
        self.hook("pre")
        self.hook("post")
        stop = self.hook("stop")
        self.assertEqual((stop.stdout, stop.stderr), ("", ""))
        self.assertFalse(self.log.exists())

    def test_missing_post_still_verifies_partial_tool_writes(self):
        self.hook("pre")
        self.write("main.ts", "const value = 2;\n")
        self.hook("stop")
        self.hook("stop")
        self.assertEqual(self.log.read_text().splitlines(), [f"{self.repo}:run verify:quick"])

    def test_missing_post_without_mutation_stays_quiet(self):
        self.write("main.ts", "const userValue = 9;\n")
        self.hook("pre")
        stop = self.hook("stop")
        again = self.hook("stop")
        self.assertEqual((stop.stdout, stop.stderr, again.stdout, again.stderr), ("", "", "", ""))
        self.assertFalse(self.log.exists())

    def test_missing_post_baseline_survives_next_call_without_tool_id(self):
        payload = dict(self.payload)
        payload.pop("tool_use_id")
        self.hook("pre", payload)
        self.write("main.ts", "const value = 2;\n")
        self.hook("pre", payload)
        self.hook("post", payload)
        self.hook("stop", payload)
        self.assertTrue(self.log.exists())

    def test_staging_existing_edits_does_not_count_as_new_code(self):
        self.write("main.ts", "const userValue = 9;\n")
        self.hook("pre")
        self.git("add", "main.ts")
        self.hook("post")
        self.hook("stop")
        self.assertFalse(self.log.exists())

    def test_committing_existing_edits_does_not_count_as_new_code(self):
        self.write("main.ts", "const userValue = 9;\n")
        self.git("add", "main.ts")
        self.hook("pre")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "user edits")
        self.hook("post")
        self.hook("stop")
        self.assertFalse(self.log.exists())

    def test_edit_and_commit_in_same_call_runs_quick_check(self):
        self.hook("pre")
        self.write("main.ts", "const value = 2;\n")
        self.git("add", "main.ts")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "tool edits")
        self.hook("post")
        self.hook("stop")
        self.assertTrue(self.log.exists())

    def test_edit_and_commit_in_same_call_catches_committed_whitespace(self):
        self.hook("pre")
        self.write("main.ts", "const value = 2;   \n")
        self.git("add", "main.ts")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "tool edits")
        self.hook("post")
        failure = json.loads(self.hook("stop").stdout)
        self.assertIn("trailing whitespace", failure["reason"])

    def test_commit_only_prior_untracked_edits_is_ignored(self):
        self.write("untracked.ts", "const userValue = 9;\n")
        self.hook("pre")
        self.git("add", "untracked.ts")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "user addition")
        self.hook("post")
        stop = self.hook("stop")
        self.assertEqual((stop.stdout, stop.stderr), ("", ""))
        self.assertFalse(self.log.exists())

    def test_changed_code_runs_quick_check_once_and_stays_quiet(self):
        self.change()
        first = self.hook("stop")
        second = self.hook("stop")
        self.assertEqual((first.stdout, first.stderr, second.stdout, second.stderr), ("", "", "", ""))
        self.assertEqual(self.log.read_text().splitlines(), [f"{self.repo}:run verify:quick"])

    def test_direct_edit_sees_formatter_result(self):
        payload = dict(self.payload, cwd=str(self.base), tool_name="Edit",
                       tool_input={"file_path": str(self.repo / "main.ts")})
        self.hook("pre", payload)
        self.write("main.ts", "const value=2;   \n")
        self.write("main.ts", "const value = 2;\n")
        self.hook("post", payload)
        self.assertEqual(self.hook("stop", payload).stdout, "")
        self.assertTrue(self.log.exists())

    def test_apply_patch_command_from_home_finds_repository(self):
        payload = dict(self.payload, cwd=str(self.base), tool_name="apply_patch",
                       tool_input={"command": f"*** Begin Patch\n*** Update File: {self.repo}/main.ts\n@@\n*** End Patch"})
        self.change(payload=payload)
        self.hook("stop", payload)
        self.assertTrue(self.log.exists())

    def test_existing_untracked_patch_target_preserves_baseline(self):
        self.write("untracked.ts", "const userValue = 1;\n")
        payload = dict(self.payload, cwd=str(self.base), tool_name="apply_patch",
                       tool_input={"command": f"*** Begin Patch\n*** Update File: {self.repo}/untracked.ts\n@@\n*** End Patch"})
        self.hook("pre", payload)
        self.hook("post", payload)
        self.hook("stop", payload)
        self.assertFalse(self.log.exists())
        self.change("untracked.ts", "const userValue = 2;\n", payload)
        self.hook("stop", payload)
        self.assertTrue(self.log.exists())

    def test_shell_workdir_and_cd_from_home_find_repository(self):
        for input_value in ({"command": "true", "workdir": str(self.repo)},
                            {"command": f"cd '{self.repo}' && true"}):
            payload = dict(self.payload, cwd=str(self.base), tool_input=input_value)
            self.change(content=f"const value = {len(input_value)};\n", payload=payload)
            self.hook("stop", payload)
        self.assertEqual(len(self.log.read_text().splitlines()), 2)

    def test_documentation_only_changes_do_not_run_project_checks(self):
        self.change("README.md", "Documentation\n")
        self.hook("stop")
        self.assertFalse(self.log.exists())

    def test_failed_quick_check_blocks_once_and_reports_output(self):
        self.fake_tool("npm", 'echo "actionable type error" >&2\nexit 1\n')
        self.change()
        first = self.hook("stop")
        decision = json.loads(first.stdout)
        self.assertEqual(decision["decision"], "block")
        self.assertIn("actionable type error", decision["reason"])
        retry = self.hook("stop", dict(self.payload, stop_hook_active=True))
        self.assertEqual(retry.stdout, "")
        self.assertIn("Previous verification failed", retry.stderr)

    def test_new_fix_is_rechecked_after_failed_stop(self):
        self.fake_tool("npm", 'exit 1\n')
        self.change()
        self.assertEqual(json.loads(self.hook("stop").stdout)["decision"], "block")
        self.fake_tool("npm", 'printf "%s\\n" "checked" >> "$CHECK_LOG"\n')
        self.change(content="const value = 3;\n")
        self.assertEqual(self.hook("stop", dict(self.payload, stop_hook_active=True)).stdout, "")
        self.assertEqual(self.log.read_text().strip(), "checked")

    def test_whitespace_failure_is_actionable(self):
        self.change(content="const value = 2;   \n")
        failure = json.loads(self.hook("stop").stdout)
        self.assertIn("git diff --check", failure["reason"])
        self.assertIn("trailing whitespace", failure["reason"])

    def test_whitespace_in_new_untracked_file_is_checked(self):
        self.change("new.ts", "const added = 1;   \n")
        failure = json.loads(self.hook("stop").stdout)
        self.assertIn("new.ts", failure["reason"])
        self.assertIn("trailing whitespace", failure["reason"])

    def test_conflict_markers_in_new_untracked_file_are_checked(self):
        self.change("new.ts", "<<<<<<< HEAD\nconst value = 1;\n=======\nconst value = 2;\n>>>>>>> branch\n")
        failure = json.loads(self.hook("stop").stdout)
        self.assertIn("new.ts", failure["reason"])
        self.assertIn("conflict marker", failure["reason"])

    def test_repository_without_initial_commit_checks_new_files(self):
        empty = self.base / "empty-repo"
        empty.mkdir()
        subprocess.run(["git", "-C", str(empty), "init", "-q"], env=self.env, check=True)
        payload = dict(self.payload, cwd=str(empty))
        self.hook("pre", payload)
        (empty / "config.json").write_text('{"valid": true}\n')
        self.hook("post", payload)
        stop = self.hook("stop", payload)
        self.assertEqual(stop.stdout, "")
        self.assertIn("no runnable project quick checker", stop.stderr)

    def test_initial_commit_checks_only_new_tool_content(self):
        empty = self.base / "empty-repo"
        empty.mkdir()
        subprocess.run(["git", "-C", str(empty), "init", "-q"], env=self.env, check=True)
        (empty / "user.py").write_text("print(1)   \n")
        payload = dict(self.payload, cwd=str(empty))
        self.hook("pre", payload)
        (empty / "agent.py").write_text("print(2)   \n")
        subprocess.run(["git", "-C", str(empty), "add", "."], env=self.env, check=True)
        subprocess.run(["git", "-C", str(empty), "-c", "user.name=Test", "-c",
                        "user.email=test@example.invalid", "commit", "-qm", "initial"],
                       env=self.env, check=True)
        self.hook("post", payload)
        failure = json.loads(self.hook("stop", payload).stdout)
        self.assertIn("agent.py", failure["reason"])
        self.assertIn("trailing whitespace", failure["reason"])
        self.assertNotIn("user.py", failure["reason"])

    def test_shell_syntax_is_checked_even_when_project_checker_exists(self):
        self.change("script.sh", "#!/bin/bash\nif true; then\n")
        failure = json.loads(self.hook("stop").stdout)
        self.assertIn("script.sh", failure["reason"])
        self.assertIn("syntax error", failure["reason"])

    def test_changing_code_after_failures_has_bounded_stop_retries(self):
        self.fake_tool("npm", 'exit 1\n')
        for value in range(2, 5):
            self.change(content=f"const value = {value};\n")
            stop = self.hook("stop", dict(self.payload, stop_hook_active=value > 2))
            if value < 4:
                self.assertEqual(json.loads(stop.stdout)["decision"], "block")
            else:
                self.assertEqual(stop.stdout, "")
                self.assertIn("Stop retry limit reached", stop.stderr)

    def test_local_tsc_and_eslint_run_without_npx(self):
        self.write("package.json", "{}\n")
        self.write("tsconfig.json", "{}\n")
        self.write("eslint.config.js", "export default [];\n")
        for name in ("tsc", "eslint"):
            binary = self.repo / "node_modules" / ".bin" / name
            binary.parent.mkdir(parents=True, exist_ok=True)
            binary.write_text(f'#!/bin/sh\nprintf "%s\\n" "{name}:$*" >> "$CHECK_LOG"\n')
            binary.chmod(0o755)
        self.change()
        stop = self.hook("stop")
        self.assertEqual((stop.stdout, stop.stderr), ("", ""))
        self.assertEqual(self.log.read_text().splitlines(), ["tsc:--noEmit", "eslint:. --quiet"])

    def test_nested_project_is_checked_without_unrelated_projects(self):
        (self.repo / "package.json").unlink()
        self.write("app/package.json", json.dumps({"scripts": {"verify:quick": "check"}}))
        self.write("unrelated/package.json", json.dumps({"scripts": {"verify:quick": "check"}}))
        self.change("app/main.ts", "const value = 2;\n")
        stop = self.hook("stop")
        self.assertEqual((stop.stdout, stop.stderr), ("", ""))
        self.assertEqual(self.log.read_text().splitlines(), [f"{self.repo}/app:run verify:quick"])

    def test_missing_project_checker_runs_json_syntax_check(self):
        self.write("package.json", "{}\n")
        self.change("config.json", '{"invalid": }\n')
        first = self.hook("stop")
        self.assertIn("config.json", json.loads(first.stdout)["reason"])
        self.assertIn("no runnable project quick checker", first.stderr)
        self.assertNotIn("no runnable project quick checker", self.hook("stop").stderr)

    def test_missing_local_typechecker_does_not_download(self):
        self.write("package.json", "{}\n")
        self.write("tsconfig.json", "{}\n")
        self.fake_tool("npx", 'echo "unexpected npx" >> "$CHECK_LOG"\nexit 99\n')
        self.change()
        stop = self.hook("stop")
        self.assertIn("local tsc unavailable", stop.stderr)
        self.assertIn("manual verification required", stop.stderr)
        self.assertFalse(self.log.exists())

    def test_invalid_package_metadata_is_a_check_failure(self):
        self.change("package.json", "{invalid}\n")
        stop = self.hook("stop")
        self.assertIn("cannot read project checker configuration", json.loads(stop.stdout)["reason"])

    def test_state_is_isolated_by_session_and_agent(self):
        self.change()
        self.hook("stop", dict(self.payload, session_id="other-session"))
        self.hook("stop", agent="codex")
        self.assertFalse(self.log.exists())
        self.hook("stop")
        self.assertTrue(self.log.exists())

    def test_session_end_clears_pending_checks(self):
        self.change()
        self.hook("session-end")
        self.hook("stop")
        self.assertFalse(self.log.exists())

    def test_timeout_returns_actionable_failure_without_hanging(self):
        result = verification.run_check(["/bin/sleep", "3"], self.repo, time.monotonic() + 0.05)
        self.assertIn("timed out", result)


if __name__ == "__main__":
    unittest.main()
