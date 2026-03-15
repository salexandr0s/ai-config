#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' ERR

[ "${AI_HOOK_TAB_TITLE:-1}" = "0" ] && exit 0

tool_name="${CLAUDE_TOOL_NAME:-}"
[ -z "$tool_name" ] && exit 0

# Extract project name from git root basename
if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  project=$(basename "$git_root")
else
  project=$(basename "$PWD")
fi

# Emit OSC title sequence to stderr (visible to terminal, not to Claude)
printf '\033]0;%s · %s\007' "$project" "$tool_name" >&2
