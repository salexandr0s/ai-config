"""Exercise the registered hook commands without launching either assistant."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class HookWiringTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.scripts = self.home / "GitHub/ai-config/scripts"
        self.scripts.mkdir(parents=True)
        self.env = {**os.environ, "HOME": str(self.home)}
        self.payload = {"session_id": "wiring-test", "cwd": str(self.home)}

    def install_script(self, name, text):
        path = self.scripts / name
        path.write_text(text)
        path.chmod(0o755)
        return path

    def install_notifier(self):
        path = self.home / "GitHub/terminal-config/bin/ai-notify"
        path.parent.mkdir(parents=True)
        path.write_text(
            "#!/bin/sh\n"
            'printf "%s %s %s %s\\n" "$1" "$2" '
            '"${AI_NOTIFY_MIN_SECONDS:-}" "${AI_NOTIFY_COOLDOWN_SECONDS:-}" '
            '> "$HOME/notification"\n'
        )
        path.chmod(0o755)

    def run_hook(self, name):
        shutil.copy2(ROOT / "scripts" / name, self.scripts / name)
        return subprocess.run(
            ["bash", str(self.scripts / name)],
            input=json.dumps(self.payload), text=True, capture_output=True,
            env=self.env, timeout=5,
        )

    def test_post_edit_tracks_formatted_content_even_on_formatter_failure(self):
        self.install_script(
            "claude-post-edit-format.sh",
            '#!/bin/sh\ncat > "$HOME/format-event"\n'
            'printf formatted > "$HOME/content"\nexit 2\n',
        )
        self.install_script(
            "hook-verification.py",
            "import json, os, pathlib, sys\n"
            "home = pathlib.Path(os.environ['HOME'])\n"
            "event = json.load(sys.stdin)\n"
            "(home/'tracked').write_text(json.dumps({'event': event, "
            "'content': (home/'content').read_text(), 'phase': sys.argv[-1]}))\n",
        )
        result = self.run_hook("claude-post-edit.sh")
        self.assertEqual(result.returncode, 2, result.stderr)
        tracked = json.loads((self.home / "tracked").read_text())
        self.assertEqual(tracked["content"], "formatted")
        self.assertEqual(tracked["event"], self.payload)
        self.assertEqual(tracked["phase"], "post")

    def test_stop_does_not_notify_while_verification_continues(self):
        self.install_notifier()
        decision = {"decision": "block", "reason": "Fix the reported errors"}
        self.install_script(
            "hook-verification.py",
            "import json, sys\njson.load(sys.stdin)\n"
            f"print({json.dumps(decision)!r})\n",
        )
        result = self.run_hook("claude-stop.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), decision)
        self.assertFalse((self.home / "notification").exists())

    def test_successful_stop_uses_existing_notifier(self):
        self.install_notifier()
        self.install_script("hook-verification.py", "import json, sys\njson.load(sys.stdin)\n")
        result = self.run_hook("claude-stop.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertTrue((self.home / "notification").read_text().startswith("claude stop"))

    def test_attention_notification_skips_minimum_duration_keeps_cooldown(self):
        self.install_notifier()
        settings = json.loads((ROOT / "claude/settings.json").read_text())
        command = settings["hooks"]["Notification"][0]["hooks"][0]["command"]
        self.env.update(AI_NOTIFY_MIN_SECONDS="99", AI_NOTIFY_COOLDOWN_SECONDS="15")
        result = subprocess.run(
            ["bash", "-c", command], env=self.env, text=True,
            capture_output=True, timeout=5,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / "notification").read_text().strip(), "claude attention 0 15")

    def test_session_end_forwards_event_to_logging_and_cleanup(self):
        self.install_script("session-capture.sh", '#!/bin/sh\ncat > "$HOME/logged-event"\n')
        self.install_script(
            "hook-verification.py",
            "import json, os, pathlib, sys\n"
            "pathlib.Path(os.environ['HOME'], 'cleanup-event').write_text(sys.stdin.read())\n",
        )
        result = self.run_hook("claude-session-end.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads((self.home / "logged-event").read_text()), self.payload)
        self.assertEqual(json.loads((self.home / "cleanup-event").read_text()), self.payload)


if __name__ == "__main__":
    unittest.main()
