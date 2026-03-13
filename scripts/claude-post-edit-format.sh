#!/usr/bin/env bash
set -euo pipefail

file_path="${1:-${CLAUDE_FILE_PATH:-}}"

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  exit 0
fi

file_dir="$(cd "$(dirname "$file_path")" && pwd)"
extension="${file_path##*.}"

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

repo_root="$(find_repo_root "$file_dir")"

run_from_root() {
  (
    cd "$repo_root"
    "$@"
  )
}

case "$extension" in
  ts|tsx|js|jsx|json|jsonc|css|scss|md|mdx|yaml|yml)
    if command -v biome >/dev/null 2>&1 && has_any_file "$repo_root" "biome.json" "biome.jsonc"; then
      run_from_root biome format --write "$file_path" >/dev/null 2>&1 || true
      exit 0
    fi
    if command -v npx >/dev/null 2>&1 && has_any_file "$repo_root" ".prettierrc" ".prettierrc.*" "prettier.config.*"; then
      run_from_root npx prettier --write "$file_path" >/dev/null 2>&1 || true
      exit 0
    fi
    ;;
  py)
    if command -v ruff >/dev/null 2>&1; then
      run_from_root ruff format "$file_path" >/dev/null 2>&1 || true
      exit 0
    fi
    ;;
  swift)
    if command -v swiftformat >/dev/null 2>&1; then
      run_from_root swiftformat "$file_path" >/dev/null 2>&1 || true
      exit 0
    fi
    ;;
  rs)
    if command -v rustfmt >/dev/null 2>&1; then
      run_from_root rustfmt "$file_path" >/dev/null 2>&1 || true
      exit 0
    fi
    ;;
esac

exit 0
