#!/bin/bash
set -euo pipefail

# Statusline debug — dumps all intermediate values for troubleshooting
# Reads same stdin JSON as statusline-command.sh

input=$(cat)

echo "=== STATUSLINE DEBUG ==="
echo ""

# ── Raw JSON fields ──
echo "--- Raw JSON Fields ---"
for field in \
  '.model.display_name' \
  '.output_style.name' \
  '.context_window.used_percentage' \
  '.cost.total_duration_ms' \
  '.cost.total_api_duration_ms' \
  '.cost.total_cost_usd'; do
  value=$(echo "$input" | jq -r "$field // \"(null)\"" 2>/dev/null || echo "(jq error)")
  printf "  %-40s = %s\n" "$field" "$value"
done
echo ""

# ── Environment variables ──
echo "--- Environment ---"
printf "  %-30s = %s\n" "AI_HOUSE_MODE" "${AI_HOUSE_MODE:-"(unset)"}"
printf "  %-30s = %s\n" "AI_HOUSE_STYLE" "${AI_HOUSE_STYLE:-"(unset)"}"
printf "  %-30s = %s\n" "AI_HOUSE_SAFETY" "${AI_HOUSE_SAFETY:-"(unset)"}"
printf "  %-30s = %s\n" "AI_HOUSE_EFFORT" "${AI_HOUSE_EFFORT:-"(unset)"}"
printf "  %-30s = %s\n" "AI_SESSION_START_TS" "${AI_SESSION_START_TS:-"(unset)"}"
printf "  %-30s = %s\n" "AI_STATUSLINE_WEATHER" "${AI_STATUSLINE_WEATHER:-"(unset)"}"
printf "  %-30s = %s\n" "CLAUDE_STATUS_COLUMNS" "${CLAUDE_STATUS_COLUMNS:-"(unset)"}"
printf "  %-30s = %s\n" "COLUMNS" "${COLUMNS:-"(unset)"}"
echo ""

# ── Terminal width ──
echo "--- Terminal Width ---"
get_width() {
  if [ -n "${CLAUDE_STATUS_COLUMNS:-}" ]; then
    echo "$CLAUDE_STATUS_COLUMNS (from CLAUDE_STATUS_COLUMNS)"
    return
  fi
  if [ -n "${COLUMNS:-}" ]; then
    echo "$COLUMNS (from COLUMNS)"
    return
  fi
  if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    local w
    w=$(tput cols 2>/dev/null || echo "0")
    echo "$w (from tput)"
    return
  fi
  echo "0 (fallback)"
}
width_info=$(get_width)
echo "  Width: $width_info"

# Extract numeric width for mode calculation
width=$(echo "$width_info" | awk '{print $1}')
if [ "$width" -eq 0 ]; then
  selected_mode="micro"
elif [ "$width" -le 60 ]; then
  selected_mode="nano"
elif [ "$width" -le 80 ]; then
  selected_mode="micro"
elif [ "$width" -le 120 ]; then
  selected_mode="mini"
else
  selected_mode="normal"
fi
echo "  Selected mode: $selected_mode"
echo ""

# ── Cache files ──
echo "--- Cache Files ---"
cache_files=(
  "/tmp/ai-statusline-weather"
  "/tmp/ai-statusline-geo"
  "/tmp/ai-statusline-signals"
)

# Add git cache for current directory
if command -v md5 >/dev/null 2>&1; then
  git_hash=$(printf '%s' "$PWD" | md5 -q 2>/dev/null || echo "unknown")
elif command -v md5sum >/dev/null 2>&1; then
  git_hash=$(printf '%s' "$PWD" | md5sum | cut -d' ' -f1)
else
  git_hash="unknown"
fi
cache_files+=("/tmp/ai-statusline-git-${git_hash}")

for cache_file in "${cache_files[@]}"; do
  if [ -f "$cache_file" ]; then
    local_now=$(date +%s)
    if stat -f '%m' "$cache_file" >/dev/null 2>&1; then
      file_mtime=$(stat -f '%m' "$cache_file")
    elif stat -c '%Y' "$cache_file" >/dev/null 2>&1; then
      file_mtime=$(stat -c '%Y' "$cache_file")
    else
      file_mtime=0
    fi
    age=$((local_now - file_mtime))
    content=$(cat "$cache_file" 2>/dev/null | head -c 200)
    printf "  %s\n    age: %ds | content: %s\n" "$cache_file" "$age" "$content"
  else
    printf "  %s\n    (not found)\n" "$cache_file"
  fi
done
echo ""

# ── Git status ──
echo "--- Git Status ---"
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "?")
  last_commit_ts=$(git log -1 --format='%ct' 2>/dev/null || echo "0")
  now=$(date +%s)
  age=$((now - last_commit_ts))
  modified=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  printf "  branch:    %s\n" "$branch"
  printf "  commit age: %ds (%dh %dm)\n" "$age" "$((age/3600))" "$(((age%3600)/60))"
  printf "  modified:  %s\n" "$modified"
  printf "  untracked: %s\n" "$untracked"
  printf "  stashes:   %s\n" "$stash_count"
else
  echo "  (not in a git repo)"
fi
echo ""

# ── Session duration ──
echo "--- Session Duration ---"
if [ -n "${AI_SESSION_START_TS:-}" ]; then
  now=$(date +%s)
  elapsed=$((now - AI_SESSION_START_TS))
  hours=$((elapsed / 3600))
  minutes=$(((elapsed % 3600) / 60))
  printf "  start_ts: %s\n" "$AI_SESSION_START_TS"
  printf "  elapsed:  %ds (%dh %dm)\n" "$elapsed" "$hours" "$minutes"
else
  echo "  (AI_SESSION_START_TS not set)"
fi
echo ""

# ── Signals ──
echo "--- Signals ---"
ratings_file="$HOME/.claude/MEMORY/SIGNALS/ratings.jsonl"
sentiment_file="$HOME/.claude/MEMORY/SIGNALS/sentiment.jsonl"
if [ -f "$ratings_file" ]; then
  count=$(wc -l < "$ratings_file" | tr -d ' ')
  avg=$(tail -50 "$ratings_file" 2>/dev/null | jq -r '.score // empty' 2>/dev/null | awk '{ sum += $1; n++ } END { if (n>0) printf "%.1f", sum/n }' 2>/dev/null || echo "(none)")
  printf "  ratings file: %s (%s lines, avg: %s)\n" "$ratings_file" "$count" "$avg"
else
  printf "  ratings file: %s (not found)\n" "$ratings_file"
fi
if [ -f "$sentiment_file" ]; then
  last_sentiment=$(tail -1 "$sentiment_file" 2>/dev/null | jq -r '.polarity // "(none)"' 2>/dev/null || echo "(parse error)")
  printf "  sentiment file: %s (last: %s)\n" "$sentiment_file" "$last_sentiment"
else
  printf "  sentiment file: %s (not found)\n" "$sentiment_file"
fi
echo ""

# ── Computed sections (what would be shown) ──
echo "--- Computed Sections ---"
used=$(echo "$input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null)
used=${used%.*}
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"' 2>/dev/null)
style_name=$(echo "$input" | jq -r '.output_style.name // "Default"' 2>/dev/null)
style_name="${style_name#House }"
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)
duration=$(echo "$input" | jq -r '.cost.total_duration_ms // 0' 2>/dev/null)

printf "  model:        %s\n" "$model_name"
printf "  style:        %s\n" "$style_name"
printf "  context used: %s%%\n" "$used"
printf "  cost:         \$%.2f\n" "$cost_usd"
printf "  duration:     %sms\n" "$duration"
printf "  house mode:   %s\n" "${AI_HOUSE_MODE:-normal}"
echo ""
echo "=== END DEBUG ==="
