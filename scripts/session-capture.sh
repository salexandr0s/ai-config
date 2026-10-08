#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' ERR

[ "${AI_HOOK_SESSION_CAPTURE:-1}" = "0" ] && exit 0

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=claude-hook-input.sh
source "$script_dir/claude-hook-input.sh"
read_claude_hook_input || exit 0

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
session_id="$HOOK_SESSION_ID"
mode="${AI_HOUSE_MODE:-normal}"
start_ts="${AI_SESSION_START_TS:-}"

# Compute duration
duration_s=0
if [[ "$start_ts" =~ ^[0-9]{1,10}$ ]]; then
  now=$(date +%s)
  duration_s=$((now - 10#$start_ts))
  [ "$duration_s" -ge 0 ] || duration_s=0
fi

# Detect project from git root or cwd
project="unknown"
if git_root=$(git -C "$HOOK_CWD" rev-parse --show-toplevel 2>/dev/null); then
  project=$(basename "$git_root")
else
  project=$(basename "$HOOK_CWD")
fi

# Write session entry
sessions_dir="$HOME/.claude/MEMORY/SESSIONS"
mkdir -p "$sessions_dir"
day_file="$sessions_dir/$(date +%Y-%m-%d).jsonl"

jq -cn --arg ts "$timestamp" --arg sid "$session_id" --argjson dur "$duration_s" \
  --arg mode "$mode" --arg proj "$project" --arg cwd "$HOOK_CWD" \
  '{timestamp:$ts, session_id:$sid, duration_s:$dur, mode:$mode, project:$proj, cwd:$cwd}' \
  >> "$day_file"

# Log event
jq -cn --arg sid "$session_id" --arg cwd "$HOOK_CWD" '{session_id:$sid, cwd:$cwd}' | \
  "$script_dir/event-logger.sh" "session-capture" "session_end" "ok" "$((duration_s * 1000))" 2>/dev/null || true
