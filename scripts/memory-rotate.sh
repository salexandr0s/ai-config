#!/usr/bin/env bash
set -euo pipefail

MEMORY_DIR="$HOME/.claude/MEMORY"

# Ensure dirs exist
mkdir -p "$MEMORY_DIR/SESSIONS/archive" "$MEMORY_DIR/SIGNALS/weekly" "$MEMORY_DIR/STATE"

rotate_sessions() {
  local cutoff_date archive_dir
  cutoff_date=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d "30 days ago" +%Y-%m-%d 2>/dev/null || return 0)

  for f in "$MEMORY_DIR/SESSIONS/"*.jsonl; do
    [ -f "$f" ] || continue
    local basename=$(basename "$f" .jsonl)
    # Compare date strings
    if [[ "$basename" < "$cutoff_date" ]]; then
      local month="${basename:0:7}"  # YYYY-MM
      archive_dir="$MEMORY_DIR/SESSIONS/archive/$month"
      mkdir -p "$archive_dir"
      gzip -c "$f" > "$archive_dir/$(basename "$f").gz"
      rm "$f"
      echo "  archived: $f"
    fi
  done
}

rotate_signals() {
  local now cutoff_ts
  now=$(date +%s)
  cutoff_ts=$((now - 7 * 86400))
  local cutoff_iso
  cutoff_iso=$(date -u -r "$cutoff_ts" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "@$cutoff_ts" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || return 0)

  for f in "$MEMORY_DIR/SIGNALS/"*.jsonl; do
    [ -f "$f" ] || continue
    local basename tmp_recent tmp_old
    basename=$(basename "$f")
    tmp_recent=$(mktemp)
    tmp_old=$(mktemp)

    # Batch partition: jq outputs to stdout (recent) or stderr (old)
    jq -c --arg cutoff "$cutoff_iso" '
      if (.timestamp // "") >= $cutoff then . else empty end
    ' "$f" > "$tmp_recent" 2>/dev/null || true

    jq -c --arg cutoff "$cutoff_iso" '
      if (.timestamp // "") < $cutoff then . else empty end
    ' "$f" > "$tmp_old" 2>/dev/null || true

    if [ -s "$tmp_old" ]; then
      local week_file="$MEMORY_DIR/SIGNALS/weekly/$(date +%Y-W%V).json"
      local count
      count=$(wc -l < "$tmp_old" | tr -d ' ')
      printf '{"source":"%s","entries":%d,"archived":"%s"}\n' "$basename" "$count" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$week_file"
      echo "  aggregated $count entries from $basename to weekly"
    fi

    if [ -s "$tmp_recent" ]; then
      mv "$tmp_recent" "$f"
    else
      : > "$f"
    fi
    rm -f "$tmp_old" "$tmp_recent" 2>/dev/null || true
  done
}

rotate_events() {
  local events_file="$MEMORY_DIR/STATE/events.jsonl"
  [ -f "$events_file" ] || return 0

  local now cutoff_ts cutoff_iso
  now=$(date +%s)
  cutoff_ts=$((now - 14 * 86400))
  cutoff_iso=$(date -u -r "$cutoff_ts" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "@$cutoff_ts" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || return 0)

  local tmp_recent tmp_old
  tmp_recent=$(mktemp)
  tmp_old=$(mktemp)

  jq -c --arg cutoff "$cutoff_iso" '
    if (.timestamp // "") >= $cutoff then . else empty end
  ' "$events_file" > "$tmp_recent" 2>/dev/null || true

  jq -c --arg cutoff "$cutoff_iso" '
    if (.timestamp // "") < $cutoff then . else empty end
  ' "$events_file" > "$tmp_old" 2>/dev/null || true

  if [ -s "$tmp_old" ]; then
    local archive="$MEMORY_DIR/STATE/events-$(date +%Y-%m-%d).jsonl.gz"
    gzip -c "$tmp_old" > "$archive"
    echo "  compressed $(wc -l < "$tmp_old" | tr -d ' ') old events"
  fi

  if [ -s "$tmp_recent" ]; then
    mv "$tmp_recent" "$events_file"
  else
    : > "$events_file"
  fi
  rm -f "$tmp_old" "$tmp_recent" 2>/dev/null || true
}

echo "Memory rotation: $(date)"
rotate_sessions
rotate_signals
rotate_events

# Write rotation record
printf '{"timestamp":"%s","sessions_size":"%s","signals_size":"%s","state_size":"%s"}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  "$(du -sh "$MEMORY_DIR/SESSIONS" 2>/dev/null | cut -f1 || echo 0)" \
  "$(du -sh "$MEMORY_DIR/SIGNALS" 2>/dev/null | cut -f1 || echo 0)" \
  "$(du -sh "$MEMORY_DIR/STATE" 2>/dev/null | cut -f1 || echo 0)" \
  > "$MEMORY_DIR/STATE/last-rotation.json"

echo "Rotation complete."
