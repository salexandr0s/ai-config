"""Guard integration tests: command strings are passed as data, never executed."""

import json
import os
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]


def run_guard(platform, payload, **env):
    result = subprocess.run(
        [str(ROOT / "scripts" / f"{platform}-pre-bash-guard.sh")],
        input=payload if isinstance(payload, str) else json.dumps(payload),
        text=True, capture_output=True, env={**os.environ, **env}, check=True,
    )
    if result.stderr:
        raise AssertionError(result.stderr)
    return json.loads(result.stdout) if result.stdout.strip() else {}


class GuardTests(unittest.TestCase):
    def test_risky_execution_asks_claude_and_denies_codex(self):
        commands = [
            "vercel deploy --prod", "vercel --prod", "fly deploy", "railway up",
            "railway deploy", "netlify deploy --prod", "terraform apply",
            "kubectl --context production apply -f manifest.yaml",
            "helm upgrade app ./chart", "helm install app ./chart",
            "supabase db push", "prisma db push", "drizzle-kit push", "rails db:migrate",
        ]
        for platform, decision in (("claude", "ask"), ("codex", "deny")):
            for command in commands:
                with self.subTest(platform=platform, command=command):
                    output = run_guard(platform, {"tool_input": {"command": command}})
                    hook = output["hookSpecificOutput"]
                    self.assertEqual(hook["hookEventName"], "PreToolUse")
                    self.assertEqual(hook["permissionDecision"], decision)
                    self.assertTrue(hook["permissionDecisionReason"])
        self.assertIn("cannot request native approval", run_guard(
            "codex", {"tool_input": {"command": "terraform apply"}}
        )["hookSpecificOutput"]["permissionDecisionReason"])

    def test_claude_reads_stdin_not_obsolete_environment(self):
        output = run_guard("claude", {"tool_input": {"command": "terraform apply"}},
                           CLAUDE_TOOL_INPUT="echo harmless")
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "ask")
        self.assertEqual(run_guard("claude", {"tool_input": {"command": "echo harmless"}},
                                   CLAUDE_TOOL_INPUT="terraform apply"), {})

    def test_mentions_read_only_commands_and_python_tests_are_quiet(self):
        commands = [
            "printf '%s\\n' 'vercel deploy --prod'",
            "echo 'terraform apply; kubectl apply'",
            "echo ';' 'vercel' deploy --prod",
            "rg 'prisma db push|helm upgrade' scripts/",
            "python3 -c 'print(\"vercel deploy --prod\")'",
            "python3 - <<'PY'\ncommand = 'terraform apply'\nassert command\nPY\n",
            "cat <<'DOC'\nvercel --prod\nterraform apply\nDOC\n",
            "cat <<DOC\nvercel --prod\nterraform apply\nDOC\n",
            "cat <<-\"DOC\"\n\tvercel --prod\n\tDOC\n",
            "# vercel --prod\nprintf '%s' '$(terraform apply)'",
            "command -v terraform", "vercel project inspect", "terraform plan",
            "kubectl get pods", "helm list", "prisma generate", "git status",
            "terraform output apply", "kubectl get configmap apply",
            "helm list --filter install", "vercel build --prod", "vercel logs --prod",
            "cat <<DOC\n'$(echo harmless)'\nDOC\n",
            "terraform apply --help", "helm install -h", "vercel --prod --help",
            "git tag", "git tag --list", "git tag -l v1", "git tag --verify v1",
            "git tag --delete v1", "git tag -d v1",
            "npm publish --dry-run", "pnpm publish --dry-run",
            "yarn publish --dry-run", "cargo publish --dry-run",
        ]
        for platform in ("claude", "codex"):
            for command in commands:
                with self.subTest(platform=platform, command=command):
                    self.assertEqual(run_guard(platform, {"tool_input": {"command": command}}), {})

    def test_literal_wrappers_shell_bodies_and_executed_substitutions(self):
        commands = [
            "cd project && vercel --prod", "echo ok; terraform apply", "echo ok | kubectl apply -f -",
            "DEPLOY_MODE=production /usr/local/bin/vercel deploy --prod",
            "env -u FOO MODE=prod vercel --prod", "sudo -u deploy terraform apply",
            "command vercel --prod", "exec vercel --prod", "npx --yes vercel@latest --prod",
            "pnpm exec vercel --prod", "npm exec -- vercel --prod",
            "bash -lc 'vercel --prod'", "bash <<'SCRIPT'\nterraform apply\nSCRIPT\n",
            'printf "%s" "$(vercel --prod)"', "echo `terraform apply`",
            "cat <<DOC\n$(terraform apply)\nDOC\n",
            "cat <<DOC\n'$(terraform apply)'\nDOC\n",
            "python3 - <<'PY'\nprint('safe example: vercel --prod')\nPY\nvercel --prod",
            "if true; then vercel --prod; fi",
        ]
        for platform, decision in (("claude", "ask"), ("codex", "deny")):
            for command in commands:
                with self.subTest(platform=platform, command=command):
                    output = run_guard(platform, {"tool_input": {"command": command}})
                    self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], decision)

    def test_external_publish_release_and_branch_push_stay_warnings(self):
        for platform in ("claude", "codex"):
            for command in ("npm publish", "pnpm publish", "yarn publish", "cargo publish",
                            "docker push app:latest", "gh release create v1", "git tag v1",
                            "git push origin main", "git push master", "git push --force origin main"):
                with self.subTest(platform=platform, command=command):
                    output = run_guard(platform, {"tool_input": {"command": command}})
                    self.assertNotIn("hookSpecificOutput", output)
                    self.assertIn("Confirm with the user first", output["systemMessage"])

    def test_mixed_commands_keep_warning_and_permission_request(self):
        for platform in ("claude", "codex"):
            output = run_guard(platform, {"tool_input": {"command": "npm publish && vercel --prod"}})
            self.assertIn("hookSpecificOutput", output)
            self.assertIn("systemMessage", output)

    def test_empty_or_malformed_input_is_quiet(self):
        for platform in ("claude", "codex"):
            for payload in ("", "not json", [], {}, {"tool_input": None},
                            {"tool_input": {"command": None}}, {"tool_input": {"command": ""}}):
                with self.subTest(platform=platform, payload=payload):
                    self.assertEqual(run_guard(platform, payload), {})


if __name__ == "__main__":
    unittest.main()
