#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' ERR

[ "${AI_HOOK_TAB_TITLE:-1}" = "0" ] && exit 0

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=claude-hook-input.sh
source "$script_dir/claude-hook-input.sh"
read_claude_hook_input || exit 0
tool_name="$HOOK_TOOL_NAME"
[ -z "$tool_name" ] && exit 0

# Extract project name from git root basename
if git_root=$(git -C "$HOOK_CWD" rev-parse --show-toplevel 2>/dev/null); then
  project=$(basename "$git_root")
else
  project=$(basename "$HOOK_CWD")
fi

# Prevent filenames or input fields from injecting terminal control sequences.
project="$(printf '%s' "$project" | jq -Rrs 'gsub("[[:cntrl:]]"; "")')"
tool_name="$(printf '%s' "$tool_name" | jq -Rrs 'gsub("[[:cntrl:]]"; "")')"

# Claude forwards terminalSequence through its interactive terminal output.
sequence="$(printf '\033]0;%s · %s\007' "$project" "$tool_name")"
jq -cn --arg sequence "$sequence" '{terminalSequence:$sequence}'
