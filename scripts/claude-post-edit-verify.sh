#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=claude-hook-input.sh
source "$script_dir/claude-hook-input.sh"
if [ -n "${1:-}" ]; then
  file_path="$1"
else
  read_claude_hook_input || exit 2
  file_path="$HOOK_FILE_PATH"
  cd "$HOOK_CWD"
fi

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  exit 0
fi

file_dir="$(cd "$(dirname "$file_path")" && pwd)"

find_repo_root() {
  local dir="$1"

  while [ "$dir" != "/" ]; do
    if [ -e "$dir/.git" ] || [ -f "$dir/package.json" ] || [ -f "$dir/pyproject.toml" ] || [ -f "$dir/Cargo.toml" ]; then
      printf '%s\n' "$dir"
      return
    fi
    dir="$(dirname "$dir")"
  done

  printf '%s\n' "$file_dir"
}

has_any_file() {
  local dir="$1"
  shift
  local pattern

  for pattern in "$@"; do
    if compgen -G "$dir/$pattern" >/dev/null; then
      return 0
    fi
  done

  return 1
}

run_from_root() {
  (
    cd "$repo_root"
    "$@"
  )
}

log() {
  printf '[verify] %s\n' "$1" >&2
}

repo_root="$(find_repo_root "$file_dir")"

has_package_json=0
[ -f "$repo_root/package.json" ] && has_package_json=1

ts_configured=0
eslint_configured=0

has_any_file "$repo_root" "tsconfig.json" "tsconfig.*.json" "jsconfig.json" && ts_configured=1
has_any_file "$repo_root" \
  "eslint.config.js" "eslint.config.mjs" "eslint.config.cjs" "eslint.config.ts" \
  ".eslintrc" ".eslintrc.json" ".eslintrc.js" ".eslintrc.cjs" ".eslintrc.yml" ".eslintrc.yaml" && eslint_configured=1

if [ "$ts_configured" -eq 0 ] && [ "$eslint_configured" -eq 0 ]; then
  if [ "$has_package_json" -eq 1 ]; then
    log "NOTE no tsconfig or ESLint config detected in $repo_root"
  fi
  exit 0
fi

failures=0
output_file="$(mktemp)"
trap 'rm -f "$output_file"' EXIT

installed_tool() {
  local tool="$1"
  if [ -x "$repo_root/node_modules/.bin/$tool" ]; then
    printf '%s\n' "$repo_root/node_modules/.bin/$tool"
  else
    command -v "$tool"
  fi
}

verify_with() {
  local name="$1"
  shift
  local tool
  if ! tool="$(installed_tool "$name")"; then
    log "FAIL $name is configured but not installed in $repo_root or on PATH"
    failures=$((failures + 1))
  elif run_from_root "$tool" "$@" >"$output_file" 2>&1; then
    :
  else
    failures=$((failures + 1))
    log "FAIL $name $*"
    tail -n 40 "$output_file" >&2 || true
  fi
}

[ "$ts_configured" -eq 0 ] || verify_with tsc --noEmit
[ "$eslint_configured" -eq 0 ] || verify_with eslint . --quiet

if [ "$failures" -gt 0 ]; then
  log "Verification failed after edit. Do not claim success until the reported issues are fixed."
  exit 2
fi

exit 0
