#!/usr/bin/env bash
set -euo pipefail

payload="$(cat 2>/dev/null || true)"
[ -z "$payload" ] && exit 0

command_input="$(printf '%s' "$payload" | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("tool_input",{}).get("command",""))' 2>/dev/null || true)"
[ -z "$command_input" ] && exit 0

warnings=()
blocks=()

warn_if_matches() {
  local pattern="$1"
  local message="$2"

  if printf '%s\n' "$command_input" | grep -qiE "$pattern"; then
    warnings+=("$message")
  fi
}

block_if_matches() {
  local pattern="$1"
  local message="$2"

  if printf '%s\n' "$command_input" | grep -qiE "$pattern"; then
    blocks+=("$message")
  fi
}

emit_system_message() {
  python3 - "$1" <<'PY'
import json, sys
print(json.dumps({"systemMessage": sys.argv[1]}))
PY
}

emit_block() {
  python3 - "$1" "$2" <<'PY'
import json, sys
reason = sys.argv[1]
msg = sys.argv[2]
obj = {
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }
}
if msg:
    obj["systemMessage"] = msg
print(json.dumps(obj))
PY
}

warn_if_matches '(npm|pnpm|yarn|cargo) publish' 'This publishes externally. Confirm with the user first.'
warn_if_matches 'docker push|gh release create|git tag' 'This creates an external release artifact. Confirm with the user first.'
block_if_matches 'vercel( |$).*--prod|vercel deploy --prod|fly deploy|railway (up|deploy)|netlify deploy --prod' 'This targets production deployment. Blocked — get explicit user approval.'
block_if_matches 'terraform apply|kubectl apply|helm upgrade|helm install' 'This changes live infrastructure. Blocked — get explicit user approval.'
block_if_matches 'supabase db push|prisma db push|drizzle-kit push|rails db:migrate' 'This mutates a database or schema. Blocked — get explicit user approval.'
warn_if_matches 'git push (origin )?(main|master)\b' 'This pushes to the default branch. Confirm with the user first.'

if [ "${#blocks[@]}" -gt 0 ]; then
  summary="${blocks[0]}"
  extra=""
  if [ "${#warnings[@]}" -gt 0 ]; then
    extra="Warnings: ${warnings[*]}"
  fi
  emit_block "$summary" "$extra"
  exit 0
fi

if [ "${#warnings[@]}" -gt 0 ]; then
  emit_system_message "Warnings: ${warnings[*]}"
fi

exit 0
