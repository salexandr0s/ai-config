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
file_path="$file_dir/$(basename "$file_path")"
extension="${file_path##*.}"

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

repo_root="$(find_repo_root "$file_dir")"

installed_tool() {
  local tool="$1"
  if [ -x "$repo_root/node_modules/.bin/$tool" ]; then
    printf '%s\n' "$repo_root/node_modules/.bin/$tool"
  elif [ -x "$repo_root/.venv/bin/$tool" ]; then
    printf '%s\n' "$repo_root/.venv/bin/$tool"
  else
    command -v "$tool"
  fi
}

format_with() {
  local tool="$1"
  shift
  local output_file
  output_file="$(mktemp)"
  if (cd "$repo_root" && "$tool" "$@") >"$output_file" 2>&1; then
    rm -f "$output_file"
  else
    printf '[format] Failed to format %s with %s.\n' "$file_path" "$(basename "$tool")" >&2
    tail -n 40 "$output_file" >&2
    rm -f "$output_file"
    exit 2
  fi
}

case "$extension" in
  ts|tsx|js|jsx|json|jsonc|css|scss|md|mdx|yaml|yml)
    if tool="$(installed_tool biome)" && has_any_file "$repo_root" "biome.json" "biome.jsonc"; then
      format_with "$tool" format --write "$file_path"
      exit 0
    fi
    if tool="$(installed_tool prettier)" && { has_any_file "$repo_root" ".prettierrc" ".prettierrc.*" "prettier.config.*" || { [ -f "$repo_root/package.json" ] && jq -e 'has("prettier")' "$repo_root/package.json" >/dev/null 2>&1; }; }; then
      format_with "$tool" --write "$file_path"
      exit 0
    fi
    ;;
  py)
    if tool="$(installed_tool ruff)"; then
      format_with "$tool" format "$file_path"
      exit 0
    fi
    ;;
  swift)
    if tool="$(installed_tool swiftformat)"; then
      format_with "$tool" "$file_path"
      exit 0
    fi
    ;;
  rs)
    if tool="$(installed_tool rustfmt)"; then
      format_with "$tool" "$file_path"
      exit 0
    fi
    ;;
esac

exit 0
