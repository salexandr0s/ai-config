#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="$HOME/.browse/state.json"

# Resolve real script location (follows all symlink levels, portable)
resolve_path() {
  local target="$1"
  while [ -L "$target" ]; do
    local dir
    dir="$(cd "$(dirname "$target")" && pwd -P)"
    local link
    link="$(readlink "$target")"
    case "$link" in
      /*) target="$link" ;;
      *)  target="$dir/$link" ;;
    esac
  done
  echo "$(cd "$(dirname "$target")" && pwd -P)"
}
SCRIPT_DIR="$(resolve_path "$0")"

BROWSE_BIN="${BROWSE_BIN:-$SCRIPT_DIR/../browse/dist/browse}"

# Fall back to source if compiled binary doesn't exist
if [ ! -x "$BROWSE_BIN" ] && command -v bun >/dev/null 2>&1; then
  BROWSE_BIN="bun $SCRIPT_DIR/../browse/src/cli.ts"
fi

is_running() {
  if [ ! -f "$STATE_FILE" ]; then
    return 1
  fi
  local port
  port=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['port'])" 2>/dev/null || echo "")
  if [ -z "$port" ]; then
    return 1
  fi
  curl -sf "http://127.0.0.1:$port/health" >/dev/null 2>&1
}

case "${1:-help}" in
  ensure)
    if is_running; then
      echo "Browse daemon already running."
    else
      echo "Starting browse daemon..."
      $BROWSE_BIN start &
      disown
      sleep 1
      if is_running; then
        echo "Browse daemon started."
      else
        echo "Failed to start browse daemon." >&2
        exit 1
      fi
    fi
    ;;
  start)
    $BROWSE_BIN start &
    disown
    sleep 1
    echo "Browse daemon started."
    ;;
  stop)
    $BROWSE_BIN stop
    ;;
  status)
    $BROWSE_BIN status
    ;;
  *)
    echo "Usage: browse-ctl {ensure|start|stop|status}"
    echo ""
    echo "  ensure  Start if not running"
    echo "  start   Start the daemon"
    echo "  stop    Stop the daemon"
    echo "  status  Show daemon status"
    ;;
esac
