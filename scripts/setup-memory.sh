#!/usr/bin/env bash
set -euo pipefail

# setup-memory.sh — idempotent scaffold for ~/.claude/MEMORY/ and cache dirs
# Run from install.sh or directly.

MEMORY_ROOT="$HOME/.claude/MEMORY"
CACHE_DIR="$HOME/.cache/ai-statusline"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ── Directory scaffold ──

mkdir -p "$MEMORY_ROOT/SESSIONS/archive"
mkdir -p "$MEMORY_ROOT/SIGNALS/weekly"
mkdir -p "$MEMORY_ROOT/LEARNINGS"
mkdir -p "$MEMORY_ROOT/STATE"
mkdir -p "$MEMORY_ROOT/RESEARCH"
mkdir -p "$MEMORY_ROOT/scripts"

# ── Markdown scaffolds (create only if missing) ──

if [ ! -f "$MEMORY_ROOT/LEARNINGS/what-works.md" ]; then
  printf '# What Works\n' > "$MEMORY_ROOT/LEARNINGS/what-works.md"
fi

if [ ! -f "$MEMORY_ROOT/LEARNINGS/what-fails.md" ]; then
  printf '# What Fails\n' > "$MEMORY_ROOT/LEARNINGS/what-fails.md"
fi

if [ ! -f "$MEMORY_ROOT/LEARNINGS/skill-improvements.md" ]; then
  printf '# Skill Improvements\n' > "$MEMORY_ROOT/LEARNINGS/skill-improvements.md"
fi

# ── State files (touch only if missing) ──

if [ ! -f "$MEMORY_ROOT/STATE/events.jsonl" ]; then
  touch "$MEMORY_ROOT/STATE/events.jsonl"
fi

if [ ! -f "$MEMORY_ROOT/STATE/active-projects.json" ]; then
  printf '{}\n' > "$MEMORY_ROOT/STATE/active-projects.json"
fi

# ── Symlink: rotate.sh ──

rotate_target="$REPO_DIR/scripts/memory-rotate.sh"
rotate_link="$MEMORY_ROOT/scripts/rotate.sh"

if [ -L "$rotate_link" ] && [ "$(readlink "$rotate_link")" = "$rotate_target" ]; then
  : # already correct
elif [ -e "$rotate_link" ] || [ -L "$rotate_link" ]; then
  rm "$rotate_link"
  ln -s "$rotate_target" "$rotate_link"
else
  ln -s "$rotate_target" "$rotate_link"
fi

# ── Cache directory ──

mkdir -p "$CACHE_DIR"
