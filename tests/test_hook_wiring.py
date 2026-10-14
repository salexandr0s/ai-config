"""Exercise the registered hook commands without launching either assistant."""

import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
HOOK_FILES = (ROOT / "claude/settings.json", ROOT / "codex/hooks.json")


def registered_commands(path):
    events = json.loads(path.read_text())["hooks"]
    return [hook["command"] for groups in events.values()
            for group in groups for hook in group["hooks"]]


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

    def run_settings_hook(self, event, payload=None):
        settings = json.loads((ROOT / "claude/settings.json").read_text())
        command = settings["hooks"][event][0]["hooks"][0]["command"]
        return subprocess.run(
            ["bash", "-c", command], input=json.dumps(payload or {}), env=self.env,
            text=True, capture_output=True, timeout=5,
        )

    def test_registered_scripts_exist(self):
        for path in HOOK_FILES:
            for command in registered_commands(path):
                for name in re.findall(r"\$HOME/GitHub/ai-config/scripts/([\w.-]+)", command):
                    self.assertTrue((ROOT / "scripts" / name).is_file(), f"{path.name}: {command}")

    def test_stop_uses_existing_notifier(self):
        self.install_notifier()
        result = self.run_settings_hook("Stop", self.payload)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertTrue((self.home / "notification").read_text().startswith("claude stop"))

    def test_attention_notification_skips_minimum_duration_keeps_cooldown(self):
        self.install_notifier()
        self.env.update(AI_NOTIFY_MIN_SECONDS="99", AI_NOTIFY_COOLDOWN_SECONDS="15")
        result = self.run_settings_hook("Notification")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / "notification").read_text().strip(), "claude attention 0 15")

    def test_session_end_forwards_event_to_session_capture(self):
        self.install_script("session-capture.sh", '#!/bin/sh\ncat > "$HOME/logged-event"\n')
        result = self.run_settings_hook("SessionEnd", self.payload)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads((self.home / "logged-event").read_text()), self.payload)


if __name__ == "__main__":
    unittest.main()
