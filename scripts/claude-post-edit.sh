#!/usr/bin/env bash
set -uo pipefail

# Both commands must see the same event, and tracking must see formatted content.
script_dir="$(cd "$(dirname "$0")" && pwd)"
payload="$(cat)"
status=0
printf '%s' "$payload" | "$script_dir/claude-post-edit-format.sh" || status=$?
printf '%s' "$payload" | python3 "$script_dir/hook-verification.py" --agent claude post || status=$?
exit "$status"
