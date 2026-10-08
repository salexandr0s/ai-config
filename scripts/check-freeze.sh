#!/usr/bin/env bash
set -euo pipefail

freeze_file="$HOME/.claude/freeze-dir.txt"
[ -f "$freeze_file" ] || exit 0

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=claude-hook-input.sh
source "$script_dir/claude-hook-input.sh"
read_claude_hook_input || exit 2
file_path="${1:-$HOOK_FILE_PATH}"
if [ -z "$file_path" ]; then
  printf 'BLOCKED: Cannot determine edit path while freeze is active.\n' >&2
  exit 2
fi

# An active restriction must also block when its path resolver is unavailable.
if ! command -v python3 >/dev/null 2>&1; then
  printf 'BLOCKED: Python 3 is required to resolve paths while freeze is active.\n' >&2
  exit 2
fi

# realpath resolves symlinks and .., including paths to files not yet created.
python3 - "$freeze_file" "$file_path" "$HOOK_CWD" <<'PY'
import os
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as stream:
        frozen = stream.read().rstrip("\r\n")
    if not frozen:
        raise ValueError("Empty freeze directory")
    frozen = os.path.realpath(frozen)
    target = os.path.realpath(os.path.join(sys.argv[3], sys.argv[2]))
    allowed = os.path.isdir(frozen) and os.path.commonpath([frozen, target]) == frozen
except (OSError, ValueError) as error:
    print(f"BLOCKED: Cannot resolve freeze paths: {error}", file=sys.stderr)
    sys.exit(2)

if not allowed:
    print(f"BLOCKED: Edit restricted to {frozen} (freeze active). Use /unfreeze to remove restriction.", file=sys.stderr)
    sys.exit(2)
PY
