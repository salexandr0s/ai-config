#!/usr/bin/env bash
set -euo pipefail

file_path="${1:-${CLAUDE_FILE_PATH:-}}"

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  exit 0
fi

file_dir="$(cd "$(dirname "$file_path")" && pwd)"

find_repo_root() {
  local dir="$1"

  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ] || [ -f "$dir/package.json" ] || [ -f "$dir/pyproject.toml" ] || [ -f "$dir/Cargo.toml" ]; then
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

if ! command -v npx >/dev/null 2>&1; then
  log "NOTE npx unavailable; cannot run post-edit JS/TS verification in $repo_root"
  exit 0
fi

failures=0
output_file="$(mktemp)"
trap 'rm -f "$output_file"' EXIT

if [ "$ts_configured" -eq 1 ]; then
  if run_from_root npx tsc --noEmit >"$output_file" 2>&1; then
    log "PASS npx tsc --noEmit"
  else
    failures=$((failures + 1))
    log "FAIL npx tsc --noEmit"
    tail -n 40 "$output_file" >&2 || true
  fi
else
  log "NOTE no tsconfig detected"
fi

: >"$output_file"
if [ "$eslint_configured" -eq 1 ]; then
  if run_from_root npx eslint . --quiet >"$output_file" 2>&1; then
    log "PASS npx eslint . --quiet"
  else
    failures=$((failures + 1))
    log "FAIL npx eslint . --quiet"
    tail -n 40 "$output_file" >&2 || true
  fi
else
  log "NOTE no ESLint config detected"
fi

if [ "$failures" -gt 0 ]; then
  log "Verification failed after edit. Do not claim success until the reported issues are fixed."
fi

exit 0
