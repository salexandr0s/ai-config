#!/usr/bin/env bash

# Sourced by Claude hooks. Claude sends context on stdin, not CLAUDE_* variables.
read_claude_hook_input() {
  HOOK_PAYLOAD=""
  if [ ! -t 0 ]; then
    HOOK_PAYLOAD="$(cat)"
  fi
  if [ -z "$HOOK_PAYLOAD" ]; then
    HOOK_PAYLOAD='{}'
    if [ -n "${CLAUDE_TOOL_INPUT:-}" ]; then
      HOOK_PAYLOAD="$(jq -cn --argjson input "$CLAUDE_TOOL_INPUT" '{tool_input:$input}')" || return 1
    fi
  fi
  if ! printf '%s' "$HOOK_PAYLOAD" | jq -e 'type == "object"' >/dev/null 2>&1; then
    printf '[hook] Invalid Claude hook JSON input.\n' >&2
    return 1
  fi
  HOOK_FILE_PATH="$(claude_hook_value '.tool_input.file_path // .tool_input.notebook_path')"
  HOOK_TOOL_NAME="$(claude_hook_value '.tool_name')"
  HOOK_SESSION_ID="$(claude_hook_value '.session_id')"
  HOOK_CWD="$(claude_hook_value '.cwd')"
  HOOK_FILE_PATH="${HOOK_FILE_PATH:-${CLAUDE_FILE_PATH:-}}"
  HOOK_TOOL_NAME="${HOOK_TOOL_NAME:-${CLAUDE_TOOL_NAME:-}}"
  HOOK_SESSION_ID="${HOOK_SESSION_ID:-${CLAUDE_SESSION_ID:-${AI_SESSION_ID:-unknown}}}"
  HOOK_CWD="${HOOK_CWD:-$PWD}"
}

claude_hook_value() {
  printf '%s' "$HOOK_PAYLOAD" | jq -r "($1) // empty | strings"
}
