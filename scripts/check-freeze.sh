#!/usr/bin/env bash
set -euo pipefail

tool_input="${CLAUDE_TOOL_INPUT:-}"

if [ -z "$tool_input" ]; then
  exit 0
fi

freeze_file="$HOME/.claude/freeze-dir.txt"

# No freeze active — allow everything
if [ ! -f "$freeze_file" ]; then
  exit 0
fi

frozen_dir="$(cat "$freeze_file")"

# Extract file_path from JSON input (handles both Edit and Write tools)
# Use python for reliable JSON parsing, fall back to grep
file_path=""
if command -v python3 >/dev/null 2>&1; then
  file_path="$(printf '%s' "$tool_input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('file_path',''))" 2>/dev/null || true)"
fi

if [ -z "$file_path" ]; then
  # Fallback: extract with grep
  file_path="$(printf '%s' "$tool_input" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"file_path"\s*:\s*"//' | sed 's/"$//' || true)"
fi

if [ -z "$file_path" ]; then
  # Can't determine path — allow (don't break workflow)
  exit 0
fi

# Resolve to absolute path
file_path="$(cd "$(dirname "$file_path")" 2>/dev/null && pwd)/$(basename "$file_path")" 2>/dev/null || file_path="$file_path"

# Check if file is under frozen directory
case "$file_path" in
  "$frozen_dir"/*)
    exit 0
    ;;
  "$frozen_dir")
    exit 0
    ;;
  *)
    printf 'BLOCKED: Edit restricted to %s (freeze active). Use /unfreeze to remove restriction.\n' "$frozen_dir" >&2
    exit 2
    ;;
esac
