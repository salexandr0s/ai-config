#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' ERR

# Usage: event-logger.sh <hook_name> <event_type> <status> [duration_ms]
# Optional stdin hook JSON supplies session_id and cwd.
# Appends to ~/.claude/MEMORY/STATE/events.jsonl

hook_name="${1:-unknown}"
event_type="${2:-unknown}"
status="${3:-unknown}"
duration_ms="${4:-0}"
if [[ "$duration_ms" =~ ^[0-9]{1,15}$ ]]; then
  duration_ms=$((10#$duration_ms))
else
  duration_ms=0
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=claude-hook-input.sh
source "$script_dir/claude-hook-input.sh"
read_claude_hook_input || exit 0

events_file="$HOME/.claude/MEMORY/STATE/events.jsonl"
mkdir -p "$(dirname "$events_file")"

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
session_id="$HOOK_SESSION_ID"

jq -cn --arg ts "$timestamp" --arg hook "$hook_name" --arg event "$event_type" \
  --arg status "$status" --argjson dur "${duration_ms:-0}" --arg sid "$session_id" \
  --arg cwd "$HOOK_CWD" \
  '{timestamp:$ts, hook:$hook, event:$event, status:$status, duration_ms:$dur, session_id:$sid, cwd:$cwd}' \
  >> "$events_file"
