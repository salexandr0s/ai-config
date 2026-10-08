#!/usr/bin/env bash
set -euo pipefail

# Compatibility entry point: record actual edits; Stop performs verification.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$script_dir/hook-verification.py" --agent codex post
