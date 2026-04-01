#!/usr/bin/env bash
set -euo pipefail

payload="$(cat 2>/dev/null || true)"
[ -z "$payload" ] && exit 0

command_input="$(printf '%s' "$payload" | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("tool_input",{}).get("command",""))' 2>/dev/null || true)"
[ -z "$command_input" ] && exit 0

if printf '%s\n' "$command_input" | grep -qiE 'sed -i|perl -pi|cat .*>|tee |cp |mv |npm install|pnpm install|yarn add|bun add|cargo add|cargo fmt|go fmt|ruff .*--fix|eslint .*--fix|prettier .*--write|biome .*--write|swiftformat|rustfmt|git apply|patch '; then
  python3 - <<'PY'
import json
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": "This Bash command may have modified files. Re-read changed files and run verification before claiming success. Codex hooks currently only see Bash, so edit-time verification still requires agent discipline."
    }
}))
PY
fi

exit 0
