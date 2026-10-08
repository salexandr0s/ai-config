#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
payload="$(cat)"
status=0
printf '%s' "$payload" | "$script_dir/session-capture.sh" || status=$?
printf '%s' "$payload" | python3 "$script_dir/hook-verification.py" --agent claude session-end || status=$?
exit "$status"
