#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' ERR

[ "${AI_HOOK_SESSION_CAPTURE:-1}" = "0" ] && exit 0

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
session_id="${CLAUDE_SESSION_ID:-${AI_SESSION_ID:-unknown}}"
mode="${AI_HOUSE_MODE:-normal}"
start_ts="${AI_SESSION_START_TS:-}"

# Compute duration
duration_s=0
if [ -n "$start_ts" ]; then
  now=$(date +%s)
  duration_s=$((now - start_ts))
fi

# Detect project from git root or cwd
project="unknown"
if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  project=$(basename "$git_root")
else
  project=$(basename "$PWD")
fi

# Write session entry
sessions_dir="$HOME/.claude/MEMORY/SESSIONS"
mkdir -p "$sessions_dir"
day_file="$sessions_dir/$(date +%Y-%m-%d).jsonl"

jq -n --arg ts "$timestamp" --arg sid "$session_id" --argjson dur "$duration_s" \
  --arg mode "$mode" --arg proj "$project" --arg cwd "$PWD" \
  '{timestamp:$ts, session_id:$sid, duration_s:$dur, mode:$mode, project:$proj, cwd:$cwd}' \
  >> "$day_file"

# Log event
script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/event-logger.sh" "session-capture" "session_end" "ok" "$((duration_s * 1000))" 2>/dev/null || true
