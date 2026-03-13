#!/bin/bash
set -euo pipefail

input=$(cat)

json_field() {
  echo "$input" | jq -r "$1"
}

format_ms() {
  local total_ms="${1:-0}"
  local total_seconds hours minutes seconds

  total_seconds=$((total_ms / 1000))
  hours=$((total_seconds / 3600))
  minutes=$(((total_seconds % 3600) / 60))
  seconds=$((total_seconds % 60))

  if [ "$hours" -gt 0 ]; then
    printf '%dh%02dm' "$hours" "$minutes"
  elif [ "$minutes" -gt 0 ]; then
    printf '%dm%02ds' "$minutes" "$seconds"
  else
    printf '%ds' "$seconds"
  fi
}

join_with_separator() {
  local separator="$1"
  shift
  local result='' item

  for item in "$@"; do
    [ -z "$item" ] && continue
    if [ -n "$result" ]; then
      result="${result}${separator}${item}"
    else
      result="$item"
    fi
  done

  printf '%s' "$result"
}

compact_style_name() {
  local value="$1"
  value="${value#House }"
  printf '%s\n' "$value"
}

get_terminal_width() {
  if [ -n "${CLAUDE_STATUS_COLUMNS:-}" ]; then
    printf '%s\n' "$CLAUDE_STATUS_COLUMNS"
    return
  fi

  if [ -n "${COLUMNS:-}" ]; then
    printf '%s\n' "$COLUMNS"
    return
  fi

  if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    tput cols 2>/dev/null || printf '0\n'
    return
  fi

  printf '0\n'
}

pad_value() {
  local width="$1"
  local value="$2"
  printf '%-*s' "$width" "$value"
}

model=$(json_field '.model.display_name // "Claude"')
style=$(json_field '.output_style.name // "Default"')
style=$(compact_style_name "$style")
used=$(json_field '.context_window.used_percentage // 0')
duration_ms=$(json_field '.cost.total_duration_ms // 0')
api_duration_ms=$(json_field '.cost.total_api_duration_ms // 0')
total_cost=$(json_field '.cost.total_cost_usd // 0')

mode="${AI_HOUSE_MODE:-normal}"
safety="${AI_HOUSE_SAFETY:-default}"
used=${used%.*}
bar_width=20
filled=$(((used + 2) / 5))
if [ "$filled" -gt "$bar_width" ]; then
  filled=$bar_width
fi

cyan=$'\033[36m'
green=$'\033[32m'
orange=$'\033[38;5;208m'
red=$'\033[31m'
dim=$'\033[90m'
reset=$'\033[0m'

bar=''
segment=1
while [ "$segment" -le "$bar_width" ]; do
  if [ "$segment" -le "$filled" ]; then
    if [ "$segment" -le 10 ]; then
      segment_color=$green
    elif [ "$segment" -le 16 ]; then
      segment_color=$orange
    else
      segment_color=$red
    fi
    bar="${bar}${segment_color}■"
  else
    bar="${bar}${dim}□"
  fi
  segment=$((segment + 1))
done

if [ "$used" -lt 50 ]; then
  ctx_color=$green
elif [ "$used" -lt 80 ]; then
  ctx_color=$orange
else
  ctx_color=$red
fi

cost_display=$(printf '$%.2f' "$total_cost")
time_display=$(format_ms "$duration_ms")
terminal_width=$(get_terminal_width)

meta_separator=" ${dim}·${reset} "
ctx_block="${ctx_color}${used}%${reset} [${bar}${reset}]"
telemetry_block="${dim}${time_display}${reset}${meta_separator}${dim}${cost_display}${reset}"

if [ "$terminal_width" -gt 0 ] && [ "$terminal_width" -lt 72 ]; then
  printf "%b" "${cyan}${model}${reset}${meta_separator}${ctx_block}"
  exit 0
fi

if [ "$terminal_width" -gt 0 ] && [ "$terminal_width" -lt 108 ]; then
  printf "%b" "${cyan}${model}${reset}${meta_separator}${ctx_block}${meta_separator}${telemetry_block}"
  exit 0
fi

printf "%b" "${cyan}${model}${reset}${meta_separator}${ctx_block}${meta_separator}${telemetry_block}"
