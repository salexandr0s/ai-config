"""Exercise Claude hooks with the stdin JSON used by Claude Code."""

import json
from pathlib import Path
import subprocess
import tempfile
import time
import unittest


SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"


class ClaudeHookInputTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.project = self.root / "project with spaces"
        self.project.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "tool.log"
        self.env = {
            "HOME": str(self.home),
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "AI_TEST_LOG": str(self.log),
        }

    def payload(self, file_path="source.ts", **context):
        return {
            "session_id": "session-from-stdin",
            "cwd": str(self.project),
            "tool_name": "Edit",
            "tool_input": {"file_path": file_path},
            **context,
        }

    def run_hook(self, name, payload=None, args=(), env=None, raw=None):
        return subprocess.run(
            ["/bin/bash", str(SCRIPTS / name), *args],
            input=raw if raw is not None else json.dumps(payload or {}),
            text=True,
            capture_output=True,
            cwd=self.root,
            env={**self.env, **(env or {})},
            timeout=10,
        )

    def fake_tool(self, name, body, local=False):
        folder = self.project / "node_modules" / ".bin" if local else self.bin
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / name
        path.write_text(f"#!/bin/bash\nset -eu\n{body}\n", encoding="utf-8")
        path.chmod(0o755)
        return path

    def configure_formatter(self, name="biome"):
        (self.project / "package.json").write_text("{}", encoding="utf-8")
        config = "biome.json" if name == "biome" else ".prettierrc"
        (self.project / config).write_text("{}", encoding="utf-8")
        source = self.project / "source.ts"
        source.write_text("let value=1;", encoding="utf-8")
        return source

    def freeze(self, directory=None):
        path = self.home / ".claude" / "freeze-dir.txt"
        path.parent.mkdir(parents=True)
        path.write_text(str(directory or self.project) + "\n", encoding="utf-8")

    def test_format_uses_stdin_cwd_and_prefers_project_local_tool(self):
        source = self.configure_formatter()
        self.fake_tool("biome", "exit 99")
        self.fake_tool(
            "biome",
            'printf "%s\\n" "$PWD" "$@" >> "$AI_TEST_LOG"\n'
            'printf "formatted\\n" > "${@: -1}"',
            local=True,
        )
        result = self.run_hook("claude-post-edit-format.sh", self.payload())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout + result.stderr, "")
        self.assertEqual(source.read_text(), "formatted\n")
        self.assertEqual(
            self.log.read_text().splitlines(),
            [str(self.project), "format", "--write", str(source)],
        )

    def test_formatter_failure_reaches_claude_on_stderr(self):
        self.configure_formatter()
        self.fake_tool("biome", 'printf "syntax error\\n" >&2\nexit 1', local=True)
        result = self.run_hook("claude-post-edit-format.sh", self.payload())
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, "")
        self.assertIn("syntax error", result.stderr)

    def test_no_formatter_download_when_project_tool_is_missing(self):
        self.configure_formatter("prettier")
        self.fake_tool("npx", 'touch "$AI_TEST_LOG"\nexit 99')
        result = self.run_hook("claude-post-edit-format.sh", self.payload())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.log.exists())

    def test_formatter_positional_file_path_still_works(self):
        source = self.configure_formatter()
        self.fake_tool("biome", 'printf "%s\\n" "$@" > "$AI_TEST_LOG"', local=True)
        result = self.run_hook("claude-post-edit-format.sh", args=(str(source),), raw="")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(source), self.log.read_text())

    def test_formatter_uses_project_python_environment(self):
        (self.project / "pyproject.toml").write_text("[project]\n", encoding="utf-8")
        source = self.project / "source.py"
        source.write_text("answer=42", encoding="utf-8")
        ruff = self.fake_tool("ruff", 'printf "%s\\n" "$@" > "$AI_TEST_LOG"')
        local_ruff = self.project / ".venv" / "bin" / "ruff"
        local_ruff.parent.mkdir(parents=True)
        ruff.rename(local_ruff)
        result = self.run_hook("claude-post-edit-format.sh", self.payload("source.py"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_text().splitlines(), ["format", str(source)])

    def test_formatter_finds_worktree_root_when_git_is_a_file(self):
        (self.project / ".git").write_text("gitdir: /unused", encoding="utf-8")
        (self.project / "biome.json").write_text("{}", encoding="utf-8")
        source = self.project / "nested" / "source.ts"
        source.parent.mkdir()
        source.write_text("let value=1;", encoding="utf-8")
        self.fake_tool("biome", 'printf "%s\\n" "$PWD" > "$AI_TEST_LOG"', local=True)
        result = self.run_hook("claude-post-edit-format.sh", self.payload("nested/source.ts"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_text().strip(), str(self.project))

    def test_verifier_returns_failure_and_runs_both_configured_tools(self):
        self.configure_formatter()
        (self.project / "tsconfig.json").write_text("{}", encoding="utf-8")
        (self.project / "eslint.config.js").write_text("export default []", encoding="utf-8")
        self.fake_tool(
            "tsc",
            'printf "tsc\\n" >> "$AI_TEST_LOG"\nprintf "type error\\n" >&2\nexit 1',
            local=True,
        )
        self.fake_tool("eslint", 'printf "eslint\\n" >> "$AI_TEST_LOG"', local=True)
        result = self.run_hook("claude-post-edit-verify.sh", self.payload())
        self.assertEqual(result.returncode, 2)
        self.assertIn("type error", result.stderr)
        self.assertEqual(self.log.read_text().splitlines(), ["tsc", "eslint"])

    def test_verifier_does_not_download_missing_configured_tool(self):
        self.configure_formatter()
        (self.project / "tsconfig.json").write_text("{}", encoding="utf-8")
        self.fake_tool("npx", 'touch "$AI_TEST_LOG"\nexit 99')
        result = self.run_hook("claude-post-edit-verify.sh", self.payload())
        self.assertEqual(result.returncode, 2)
        self.assertIn("not installed", result.stderr)
        self.assertFalse(self.log.exists())

    def test_freeze_is_opt_in(self):
        result = self.run_hook("check-freeze.sh", raw="not JSON")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_freeze_allows_new_nested_files_with_relative_paths(self):
        self.freeze()
        result = self.run_hook("check-freeze.sh", self.payload("new folder/new.ts"))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_freeze_denies_traversal_prefix_siblings_and_symlink_escapes(self):
        self.freeze()
        sibling = self.root / "project with spaces-sibling"
        sibling.mkdir()
        (self.project / "escape").symlink_to(sibling, target_is_directory=True)
        for file_path in ("../outside.ts", str(sibling / "source.ts"), "escape/new.ts"):
            with self.subTest(file_path=file_path):
                result = self.run_hook("check-freeze.sh", self.payload(file_path))
                self.assertEqual(result.returncode, 2)
                self.assertIn("BLOCKED", result.stderr)

    def test_active_freeze_denies_malformed_or_missing_edit_path(self):
        self.freeze()
        for raw in ("not JSON", "{}"):
            with self.subTest(raw=raw):
                result = self.run_hook("check-freeze.sh", raw=raw)
                self.assertEqual(result.returncode, 2)

    def test_notebook_edit_path_is_understood(self):
        self.freeze()
        payload = self.payload(tool_name="NotebookEdit")
        payload["tool_input"] = {"notebook_path": "../outside.ipynb"}
        result = self.run_hook("check-freeze.sh", payload)
        self.assertEqual(result.returncode, 2)

    def test_tab_title_uses_stdin_tool_and_project_and_honors_opt_out(self):
        result = self.run_hook("tab-title-update.sh", self.payload())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(
            json.loads(result.stdout),
            {"terminalSequence": "\x1b]0;project with spaces · Edit\x07"},
        )
        disabled = self.run_hook(
            "tab-title-update.sh", self.payload(), env={"AI_HOOK_TAB_TITLE": "0"}
        )
        self.assertEqual(disabled.stdout + disabled.stderr, "")

    def test_tab_title_removes_embedded_terminal_control_characters(self):
        result = self.run_hook(
            "tab-title-update.sh", self.payload(tool_name="Edit\x07\x1b[2J\n")
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(
            json.loads(result.stdout),
            {"terminalSequence": "\x1b]0;project with spaces · Edit[2J\x07"},
        )

    def test_tab_title_stays_quiet_without_tool_name(self):
        result = self.run_hook("tab-title-update.sh", self.payload(tool_name=""))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout + result.stderr, "")

    def read_json_lines(self, path):
        return [json.loads(line) for line in path.read_text().splitlines()]

    def session_entries(self):
        files = list((self.home / ".claude" / "MEMORY" / "SESSIONS").glob("*.jsonl"))
        self.assertEqual(len(files), 1)
        return self.read_json_lines(files[0])

    def event_entries(self):
        return self.read_json_lines(self.home / ".claude" / "MEMORY" / "STATE" / "events.jsonl")

    def test_session_capture_writes_compact_metadata_and_matching_event_context(self):
        payload = self.payload(
            hook_event_name="SessionEnd",
            transcript_path="/secret/transcript.jsonl",
            tool_input={"file_path": "source.ts", "content": "private text"},
        )
        for _ in range(2):
            result = self.run_hook(
                "session-capture.sh",
                payload,
                env={"CLAUDE_SESSION_ID": "stale-environment-session"},
            )
            self.assertEqual(result.returncode, 0, result.stderr)
        sessions = self.session_entries()
        events = self.event_entries()
        self.assertEqual(len(sessions), 2)
        self.assertEqual(len(events), 2)
        for entry in sessions + events:
            self.assertEqual(entry["session_id"], "session-from-stdin")
            self.assertEqual(entry["cwd"], str(self.project))
            self.assertNotIn("private text", json.dumps(entry))
            self.assertNotIn("transcript", json.dumps(entry))
        self.assertEqual(sessions[0]["duration_s"], 0)
        self.assertEqual(sessions[0]["project"], "project with spaces")
        self.assertEqual(events[0]["duration_ms"], 0)
        self.assertEqual(events[0]["event"], "session_end")

    def test_session_capture_duration_is_safe_for_invalid_or_future_start(self):
        for start in ("not-a-time", str(int(time.time()) + 3600)):
            with self.subTest(start=start):
                result = self.run_hook(
                    "session-capture.sh", self.payload(), env={"AI_SESSION_START_TS": start}
                )
                self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(all(entry["duration_s"] == 0 for entry in self.session_entries()))

    def test_session_capture_duration_and_opt_out(self):
        disabled = self.run_hook(
            "session-capture.sh", self.payload(), env={"AI_HOOK_SESSION_CAPTURE": "0"}
        )
        self.assertEqual(disabled.returncode, 0, disabled.stderr)
        self.assertFalse((self.home / ".claude" / "MEMORY").exists())
        result = self.run_hook(
            "session-capture.sh",
            self.payload(),
            env={"AI_SESSION_START_TS": str(int(time.time()) - 60)},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        duration = self.session_entries()[0]["duration_s"]
        self.assertGreaterEqual(duration, 60)
        self.assertLess(duration, 70)
        self.assertEqual(self.event_entries()[0]["duration_ms"], duration * 1000)

    def test_event_logger_positional_arguments_and_duration_defaults(self):
        for duration in ("", "invalid", "-1", "00015"):
            with self.subTest(duration=duration):
                result = self.run_hook(
                    "event-logger.sh",
                    self.payload(),
                    args=("test-hook", "test_event", "ok", duration),
                )
                self.assertEqual(result.returncode, 0, result.stderr)
        events = self.event_entries()
        self.assertEqual([entry["duration_ms"] for entry in events], [0, 0, 0, 15])
        self.assertTrue(all(entry["session_id"] == "session-from-stdin" for entry in events))


if __name__ == "__main__":
    unittest.main()
