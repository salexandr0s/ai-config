#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' ERR

[ "${AI_HOOK_VERSION_CHECK:-1}" = "0" ] && exit 0

debounce_file="/tmp/ai-config-version-check"
max_age=$((24 * 3600))  # 24 hours

# Debounce check
if [ -f "$debounce_file" ]; then
  file_mtime=$(stat -f %m "$debounce_file" 2>/dev/null || stat -c '%Y' "$debounce_file" 2>/dev/null || echo 0)
  file_age=$(( $(date +%s) - file_mtime ))
  if [ "$file_age" -lt "$max_age" ]; then
    exit 0
  fi
fi

# Fetch latest tags (quiet, bounded timeout)
ai_config_dir="$HOME/GitHub/ai-config"
[ -d "$ai_config_dir/.git" ] || exit 0

GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=3 \
  git -C "$ai_config_dir" fetch --tags --quiet 2>/dev/null || exit 0

# Touch debounce file AFTER successful fetch
touch "$debounce_file"

# Compare versions
current_version="${AI_CONFIG_VERSION:-0.0.0}"
latest_tag=$(git -C "$ai_config_dir" tag --sort=-v:refname 2>/dev/null | head -1 || echo "")
latest_version="${latest_tag#v}"

if [ -n "$latest_version" ] && [ "$latest_version" != "$current_version" ]; then
  printf '\033[33m[ai-config] Update available: %s → %s (run install.sh to upgrade)\033[0m\n' \
    "$current_version" "$latest_version" >&2
fi
