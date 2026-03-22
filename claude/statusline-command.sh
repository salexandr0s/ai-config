#!/bin/bash
set -euo pipefail

# Statusline v2 for Claude Code — 5 responsive modes, multi-line
# Reads JSON from stdin with model, style, context, cost, rate_limits fields.
# Modes: nano (<=60), micro (<=80), mini (<=120), normal (<=160), wide (>160)
#
# Line 1: Identity — model, project/branch, style, context bar, agent, worktree
# Line 2: Metrics — duration, cost, lines changed, cache %, rate limits
# Line 3: Environment — git details, mode, session, signals, weather

input=$(cat)

# ── JSON helpers ──

json_field() {
  echo "$input" | jq -r "$1"
}

# ── Formatting ──

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

compact_style_name() {
  local value="$1"
  value="${value#House }"
  printf '%s' "$value"
}

get_terminal_width() {
  if [ -n "${CLAUDE_STATUS_COLUMNS:-}" ]; then
    printf '%s' "$CLAUDE_STATUS_COLUMNS"
    return
  fi
  if [ -n "${COLUMNS:-}" ]; then
    printf '%s' "$COLUMNS"
    return
  fi
  if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    tput cols 2>/dev/null || printf '0'
    return
  fi
  printf '0'
}

# ── Colors ──

cyan=$'\033[36m'
green=$'\033[32m'
yellow=$'\033[33m'
orange=$'\033[38;5;208m'
red=$'\033[31m'
dim=$'\033[90m'
reset=$'\033[0m'

sep=" ${dim}|${reset} "

# ── Cache functions ──

read_cache() {
  local file="$1"
  local max_age="$2"
  if [ ! -f "$file" ]; then
    return
  fi
  local now file_mtime age
  now=$(date +%s)
  if stat -f '%m' "$file" >/dev/null 2>&1; then
    file_mtime=$(stat -f '%m' "$file")
  elif stat -c '%Y' "$file" >/dev/null 2>&1; then
    file_mtime=$(stat -c '%Y' "$file")
  else
    return
  fi
  age=$((now - file_mtime))
  if [ "$age" -le "$max_age" ]; then
    cat "$file"
  fi
}

refresh_bg() {
  local file="$1"
  shift
  ( "$@" > "$file" 2>/dev/null ) &
  disown 2>/dev/null || true
}

# ── Section: Project/Branch (always shown) ──

project_branch_section() {
  local project_dir branch project_name
  project_dir=$(json_field '.workspace.project_dir // ""')
  if [ -z "$project_dir" ]; then
    project_dir=$(json_field '.cwd // ""')
  fi
  project_name="${project_dir##*/}"
  [ -z "$project_name" ] && project_name="?"

  branch=""
  if command -v git >/dev/null 2>&1; then
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "")
  fi

  if [ -n "$branch" ]; then
    printf '%s' "${orange}${project_name}${reset}/${green}${branch}${reset}"
  else
    printf '%s' "${orange}${project_name}${reset}"
  fi
}

# ── Section: Git status (detailed) ──

git_section() {
  if ! command -v git >/dev/null 2>&1; then
    return
  fi
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return
  fi

  local cache_key cache_file cached
  cache_key=$(printf '%s' "$PWD" | if command -v md5 >/dev/null 2>&1; then md5 -q; else md5sum | cut -d' ' -f1; fi)
  [ -z "$cache_key" ] && cache_key="default"
  cache_file="/tmp/ai-statusline-git-${cache_key}"
  cached=$(read_cache "$cache_file" 5)
  if [ -n "$cached" ]; then
    printf '%s' "$cached"
    return
  fi

  local branch commit_age_color commit_age_str modified untracked stash_count parts
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "?")

  local last_commit_ts now age_seconds
  last_commit_ts=$(git log -1 --format='%ct' 2>/dev/null || echo "0")
  now=$(date +%s)
  age_seconds=$((now - last_commit_ts))

  if [ "$age_seconds" -lt 3600 ]; then
    commit_age_color=$green
    commit_age_str="<1h"
  elif [ "$age_seconds" -lt 86400 ]; then
    commit_age_color=$yellow
    local hours=$((age_seconds / 3600))
    commit_age_str="${hours}h"
  else
    commit_age_color=$red
    local days=$((age_seconds / 86400))
    commit_age_str="${days}d"
  fi

  modified=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

  parts="${dim}${branch}${reset} ${commit_age_color}${commit_age_str}${reset}"
  if [ "$modified" -gt 0 ]; then
    parts="${parts} ${orange}~${modified}${reset}"
  fi
  if [ "$untracked" -gt 0 ]; then
    parts="${parts} ${dim}+${untracked}${reset}"
  fi
  if [ "$stash_count" -gt 0 ]; then
    parts="${parts} ${dim}s${stash_count}${reset}"
  fi

  printf '%s' "$parts" > "$cache_file"
  printf '%s' "$parts"
}

# ── Section: Lines changed ──

lines_section() {
  local added="${1:-0}" removed="${2:-0}"
  added=${added%.*}
  removed=${removed%.*}
  if [ "$added" -eq 0 ] && [ "$removed" -eq 0 ]; then
    return
  fi
  printf '%s' "${green}+${added}${reset}${dim}/${reset}${red}-${removed}${reset}"
}

lines_section_verbose() {
  local added="${1:-0}" removed="${2:-0}"
  added=${added%.*}
  removed=${removed%.*}
  if [ "$added" -eq 0 ] && [ "$removed" -eq 0 ]; then
    return
  fi
  printf '%s' "${green}+${added}${reset}${dim}/${reset}${red}-${removed}${reset} ${dim}lines${reset}"
}

# ── Section: Cache hit ratio ──

cache_section() {
  local cache_read="${1:-0}" total_input="${2:-0}"
  cache_read=${cache_read%.*}
  total_input=${total_input%.*}
  if [ "$total_input" -eq 0 ]; then
    return
  fi
  local pct color
  pct=$((cache_read * 100 / total_input))
  if [ "$pct" -ge 60 ]; then
    color=$green
  elif [ "$pct" -ge 30 ]; then
    color=$yellow
  else
    color=$red
  fi
  printf '%s' "${dim}cache ${color}${pct}%${reset}"
}

# ── Section: Rate limits ──

rate_limits_section() {
  local five_hr="${1:-}" seven_day="${2:-}"
  local parts=""

  if [ -n "$five_hr" ] && [ "$five_hr" != "null" ] && [ "$five_hr" != "0" ]; then
    five_hr=${five_hr%.*}
    local color
    if [ "$five_hr" -lt 50 ]; then
      color=$green
    elif [ "$five_hr" -lt 80 ]; then
      color=$orange
    else
      color=$red
    fi
    parts="${dim}5hr ${color}${five_hr}%${reset}"
  fi

  if [ -n "$seven_day" ] && [ "$seven_day" != "null" ] && [ "$seven_day" != "0" ]; then
    seven_day=${seven_day%.*}
    local color
    if [ "$seven_day" -lt 50 ]; then
      color=$green
    elif [ "$seven_day" -lt 80 ]; then
      color=$orange
    else
      color=$red
    fi
    if [ -n "$parts" ]; then
      parts="${parts} ${dim}7d ${color}${seven_day}%${reset}"
    else
      parts="${dim}7d ${color}${seven_day}%${reset}"
    fi
  fi

  printf '%s' "$parts"
}

rate_limits_section_verbose() {
  local five_hr="${1:-}" seven_day="${2:-}"
  local parts=""

  if [ -n "$five_hr" ] && [ "$five_hr" != "null" ] && [ "$five_hr" != "0" ]; then
    five_hr=${five_hr%.*}
    local color
    if [ "$five_hr" -lt 50 ]; then
      color=$green
    elif [ "$five_hr" -lt 80 ]; then
      color=$orange
    else
      color=$red
    fi
    parts="${dim}5hr: ${color}${five_hr}%${reset}"
  fi

  if [ -n "$seven_day" ] && [ "$seven_day" != "null" ] && [ "$seven_day" != "0" ]; then
    seven_day=${seven_day%.*}
    local color
    if [ "$seven_day" -lt 50 ]; then
      color=$green
    elif [ "$seven_day" -lt 80 ]; then
      color=$orange
    else
      color=$red
    fi
    if [ -n "$parts" ]; then
      parts="${parts}${sep}${dim}7d: ${color}${seven_day}%${reset}"
    else
      parts="${dim}7d: ${color}${seven_day}%${reset}"
    fi
  fi

  printf '%s' "$parts"
}

# ── Section: Weather ──

weather_section() {
  if [ "${AI_STATUSLINE_WEATHER:-1}" = "0" ]; then
    return
  fi
  local cache_file="/tmp/ai-statusline-weather"
  local cached
  cached=$(read_cache "$cache_file" 900)
  if [ -n "$cached" ]; then
    printf '%s' "${dim}${cached}${reset}"
    return
  fi
  refresh_bg "$cache_file" /bin/bash -c '_fetch_weather_standalone() {
    geo_file="/tmp/ai-statusline-geo"
    geo_data=""
    if [ -f "$geo_file" ]; then
      now=$(date +%s)
      if stat -f "%m" "$geo_file" >/dev/null 2>&1; then
        mtime=$(stat -f "%m" "$geo_file")
      elif stat -c "%Y" "$geo_file" >/dev/null 2>&1; then
        mtime=$(stat -c "%Y" "$geo_file")
      else
        mtime=0
      fi
      if [ $((now - mtime)) -le 3600 ]; then
        geo_data=$(cat "$geo_file")
      fi
    fi
    if [ -z "$geo_data" ]; then
      geo_data=$(curl -s --max-time 3 "https://ipinfo.io/json" 2>/dev/null | jq -r "\"\\(.loc // \"0,0\")|\\(.city // \"\")\"" 2>/dev/null || echo "")
      if [ -n "$geo_data" ]; then
        printf "%s" "$geo_data" > "$geo_file"
      fi
    fi
    loc="${geo_data%%|*}"
    city="${geo_data#*|}"
    lat="${loc%%,*}"
    lon="${loc#*,}"
    if [ -z "$lat" ] || [ "$lat" = "0" ]; then
      exit 0
    fi
    weather_json=$(curl -s --max-time 3 "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weather_code" 2>/dev/null || echo "")
    if [ -z "$weather_json" ]; then
      exit 0
    fi
    temp=$(echo "$weather_json" | jq -r ".current.temperature_2m // \"\"" 2>/dev/null)
    code=$(echo "$weather_json" | jq -r ".current.weather_code // 0" 2>/dev/null)
    case "$code" in
      0) cond="Clear" ;;
      1|2|3) cond="Cloudy" ;;
      45|48) cond="Fog" ;;
      51|53|55|56|57) cond="Drizzle" ;;
      61|63|65|66|67) cond="Rain" ;;
      71|73|75|77) cond="Snow" ;;
      80|81|82) cond="Showers" ;;
      85|86) cond="SnowSh" ;;
      95|96|99) cond="Storm" ;;
      *) cond="" ;;
    esac
    result=""
    [ -n "$temp" ] && result="${temp}C"
    [ -n "$cond" ] && result="${result:+${result} }${cond}"
    [ -n "$city" ] && result="${result:+${result} }${city}"
    echo "$result"
  }; _fetch_weather_standalone'
}

# ── Section: Signals ──

signals_section() {
  local cache_file="/tmp/ai-statusline-signals"
  local cached
  cached=$(read_cache "$cache_file" 30)
  if [ -n "$cached" ]; then
    printf '%s' "$cached"
    return
  fi

  local ratings_file="$HOME/.claude/MEMORY/SIGNALS/ratings.jsonl"
  local sentiment_file="$HOME/.claude/MEMORY/SIGNALS/sentiment.jsonl"
  local result=""

  if [ -f "$ratings_file" ]; then
    local avg
    avg=$(tail -50 "$ratings_file" 2>/dev/null | jq -r '.score // empty' 2>/dev/null | awk '{ sum += $1; n++ } END { if (n>0) printf "%.1f", sum/n }' 2>/dev/null || echo "")
    if [ -n "$avg" ]; then
      result="${yellow}*${reset} ${avg}"
    fi
  fi

  if [ -f "$sentiment_file" ]; then
    local trend
    trend=$(tail -1 "$sentiment_file" 2>/dev/null | jq -r '.polarity // empty' 2>/dev/null || echo "")
    if [ -n "$trend" ]; then
      local arrow
      case "$trend" in
        positive) arrow="${green}^${reset}" ;;
        negative) arrow="${red}v${reset}" ;;
        *) arrow="${dim}-${reset}" ;;
      esac
      if [ -n "$result" ]; then
        result="${result}${sep}${arrow} ${trend}"
      else
        result="${arrow} ${trend}"
      fi
    fi
  fi

  if [ -n "$result" ]; then
    printf '%s' "$result" > "$cache_file"
    printf '%s' "$result"
  fi
}

# ── Section: Session duration ──

session_duration() {
  local verbose="${1:-false}"
  local start_ts="${AI_SESSION_START_TS:-}"
  if [ -z "$start_ts" ]; then
    return
  fi
  local now elapsed hours minutes
  now=$(date +%s)
  elapsed=$((now - start_ts))
  if [ "$elapsed" -lt 0 ]; then
    return
  fi
  hours=$((elapsed / 3600))
  minutes=$(((elapsed % 3600) / 60))
  local suffix=""
  [ "$verbose" = "true" ] && suffix=" session"
  if [ "$hours" -gt 0 ]; then
    printf '%s' "${dim}${hours}h ${minutes}m${suffix}${reset}"
  else
    printf '%s' "${dim}${minutes}m${suffix}${reset}"
  fi
}

# ── Context bar builder ──

build_context_bar() {
  local bar_width="$1"
  local used_pct="$2"
  local filled=$(( (used_pct * bar_width + 50) / 100 ))
  if [ "$filled" -gt "$bar_width" ]; then
    filled=$bar_width
  fi

  local bar=''
  local seg=1
  while [ "$seg" -le "$bar_width" ]; do
    if [ "$seg" -le "$filled" ]; then
      local seg_pct=$(( (seg * 100) / bar_width ))
      if [ "$seg_pct" -le 50 ]; then
        bar="${bar}${green}#"
      elif [ "$seg_pct" -le 80 ]; then
        bar="${bar}${orange}#"
      else
        bar="${bar}${red}#"
      fi
    else
      bar="${bar}${dim}-${reset}"
    fi
    seg=$((seg + 1))
  done
  printf '%s' "$bar"
}

# ── Append helper (adds separator if target non-empty) ──

append() {
  local target="$1" addition="$2"
  if [ -z "$addition" ]; then
    printf '%s' "$target"
    return
  fi
  if [ -n "$target" ]; then
    printf '%s' "${target}${sep}${addition}"
  else
    printf '%s' "$addition"
  fi
}

# ── Extract fields ──

model=$(json_field '.model.display_name // "Claude"')
style=$(json_field '.output_style.name // "Default"')
style=$(compact_style_name "$style")
used=$(json_field '.context_window.used_percentage // 0')
duration_ms=$(json_field '.cost.total_duration_ms // 0')
total_cost=$(json_field '.cost.total_cost_usd // 0')
lines_added=$(json_field '.cost.total_lines_added // 0')
lines_removed=$(json_field '.cost.total_lines_removed // 0')
cache_read=$(json_field '.context_window.current_usage.cache_read_input_tokens // 0')
total_input=$(json_field '.context_window.total_input_tokens // 0')
rate_5hr=$(json_field '.rate_limits.five_hour.used_percentage // ""')
rate_7d=$(json_field '.rate_limits.seven_day.used_percentage // ""')
agent_name=$(json_field '.agent.name // ""')
wt_branch=$(json_field '.worktree.branch // ""')

mode="${AI_HOUSE_MODE:-normal}"
used=${used%.*}

# ── Context color ──

if [ "$used" -lt 50 ]; then
  ctx_color=$green
elif [ "$used" -lt 80 ]; then
  ctx_color=$orange
else
  ctx_color=$red
fi

# ── Common pieces ──

cost_display=$(printf '$%.2f' "$total_cost")
time_display=$(format_ms "$duration_ms")
proj_branch=$(project_branch_section)

# ── Determine responsive mode ──

terminal_width=$(get_terminal_width)

if [ "$terminal_width" -eq 0 ]; then
  display_mode="micro"
elif [ "$terminal_width" -le 60 ]; then
  display_mode="nano"
elif [ "$terminal_width" -le 80 ]; then
  display_mode="micro"
elif [ "$terminal_width" -le 120 ]; then
  display_mode="mini"
elif [ "$terminal_width" -le 160 ]; then
  display_mode="normal"
else
  display_mode="wide"
fi

# ── Build output by mode ──

case "$display_mode" in

  nano)
    # 1 line: Model | project/branch | context bar (10 segments)
    bar=$(build_context_bar 10 "$used")
    printf "%b" "${cyan}${model}${reset}${sep}${proj_branch}${sep}${ctx_color}${used}%${reset} [${bar}${reset}]"
    ;;

  micro)
    # 2 lines
    # L1: Model | project/branch | style | context bar (20 segments)
    # L2: duration | cost | lines changed
    bar=$(build_context_bar 20 "$used")
    L1="${cyan}${model}${reset}${sep}${proj_branch}${sep}${dim}${style}${reset}${sep}${ctx_color}${used}%${reset} [${bar}${reset}]"

    L2="${dim}${time_display}${reset}${sep}${dim}${cost_display}${reset}"
    lines_block=$(lines_section "$lines_added" "$lines_removed")
    [ -n "$lines_block" ] && L2="${L2}${sep}${lines_block}"

    printf "%b\n%b" "$L1" "$L2"
    ;;

  mini)
    # 2 lines
    # L1: Model | project/branch | style | context bar (20) | duration | cost
    # L2: git details | lines | cache | rate limits | mode
    bar=$(build_context_bar 20 "$used")
    L1="${cyan}${model}${reset}${sep}${proj_branch}${sep}${dim}${style}${reset}${sep}${ctx_color}${used}%${reset} [${bar}${reset}]${sep}${dim}${time_display}${reset}${sep}${dim}${cost_display}${reset}"

    git_block=$(git_section)
    lines_block=$(lines_section "$lines_added" "$lines_removed")
    cache_block=$(cache_section "$cache_read" "$total_input")
    rate_block=$(rate_limits_section "$rate_5hr" "$rate_7d")

    L2=""
    [ -n "$git_block" ] && L2=$(append "$L2" "$git_block")
    [ -n "$lines_block" ] && L2=$(append "$L2" "$lines_block")
    [ -n "$cache_block" ] && L2=$(append "$L2" "$cache_block")
    [ -n "$rate_block" ] && L2=$(append "$L2" "$rate_block")
    L2=$(append "$L2" "${dim}${mode}${reset}")

    printf "%b\n%b" "$L1" "$L2"
    ;;

  normal)
    # 3 lines
    # L1: Model | project/branch | style | context bar (20) | agent | worktree
    # L2: duration | cost | lines | cache | rate limits
    # L3: git details | mode | session | signals | weather
    bar=$(build_context_bar 20 "$used")
    L1="${cyan}${model}${reset}${sep}${proj_branch}${sep}${dim}${style}${reset}${sep}${ctx_color}${used}%${reset} [${bar}${reset}]"
    [ -n "$agent_name" ] && L1="${L1}${sep}${cyan}@${agent_name}${reset}"
    [ -n "$wt_branch" ] && L1="${L1}${sep}${yellow}wt:${wt_branch}${reset}"

    L2="${dim}${time_display}${reset}${sep}${dim}${cost_display}${reset}"
    lines_block=$(lines_section "$lines_added" "$lines_removed")
    cache_block=$(cache_section "$cache_read" "$total_input")
    rate_block=$(rate_limits_section "$rate_5hr" "$rate_7d")
    [ -n "$lines_block" ] && L2="${L2}${sep}${lines_block}"
    [ -n "$cache_block" ] && L2="${L2}${sep}${cache_block}"
    [ -n "$rate_block" ] && L2="${L2}${sep}${rate_block}"

    git_block=$(git_section)
    session_block=$(session_duration)
    signals_block=$(signals_section)
    weather_block=$(weather_section)

    L3="${dim}${mode}${reset}"
    [ -n "$git_block" ] && L3=$(append "$L3" "$git_block")
    [ -n "$session_block" ] && L3=$(append "$L3" "$session_block")
    [ -n "$signals_block" ] && L3=$(append "$L3" "$signals_block")
    [ -n "$weather_block" ] && L3=$(append "$L3" "$weather_block")

    printf "%b\n%b\n%b" "$L1" "$L2" "$L3"
    ;;

  wide)
    # 3 lines — spacious, full labels
    # L1: Model (full) | project/branch | style | context bar (32) | agent | worktree
    # L2: duration | cost | lines (verbose) | cache | rate limits (verbose)
    # L3: git details | mode | session (verbose) | signals | weather
    bar=$(build_context_bar 32 "$used")
    L1="${cyan}${model}${reset}${sep}${proj_branch}${sep}${dim}${style}${reset}${sep}${ctx_color}${used}%${reset} [${bar}${reset}]"
    [ -n "$agent_name" ] && L1="${L1}${sep}${cyan}@${agent_name}${reset}"
    [ -n "$wt_branch" ] && L1="${L1}${sep}${yellow}wt:${wt_branch}${reset}"

    L2="${dim}${time_display}${reset}${sep}${dim}${cost_display}${reset}"
    lines_block=$(lines_section_verbose "$lines_added" "$lines_removed")
    cache_block=$(cache_section "$cache_read" "$total_input")
    rate_block=$(rate_limits_section_verbose "$rate_5hr" "$rate_7d")
    [ -n "$lines_block" ] && L2="${L2}${sep}${lines_block}"
    [ -n "$cache_block" ] && L2="${L2}${sep}${cache_block}"
    [ -n "$rate_block" ] && L2="${L2}${sep}${rate_block}"

    git_block=$(git_section)
    session_block=$(session_duration true)
    signals_block=$(signals_section)
    weather_block=$(weather_section)

    L3="${dim}${mode}${reset}"
    [ -n "$git_block" ] && L3=$(append "$L3" "$git_block")
    [ -n "$session_block" ] && L3=$(append "$L3" "$session_block")
    [ -n "$signals_block" ] && L3=$(append "$L3" "$signals_block")
    [ -n "$weather_block" ] && L3=$(append "$L3" "$weather_block")

    printf "%b\n%b\n%b" "$L1" "$L2" "$L3"
    ;;

esac
