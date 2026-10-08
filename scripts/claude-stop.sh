#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
status=0
output="$(python3 "$script_dir/hook-verification.py" --agent claude stop)" || status=$?
if [ -n "$output" ]; then
  printf '%s\n' "$output"
fi

# A verification decision asks Claude to continue; completion hasn't happened yet.
if [ "$status" -eq 0 ] && [ -z "$output" ]; then
  "$HOME/GitHub/terminal-config/bin/ai-notify" claude stop >/dev/null 2>&1 || true
fi
exit "$status"
