#!/usr/bin/env bash
set -euo pipefail

# ai-config installer — creates symlinks from tool config dirs to this repo
# Usage: ./install.sh [--workspace DIR] [--with-browse] [--with-launchagent]
#
# Safe: backs up existing files/dirs before overwriting.
# Idempotent: re-running updates symlinks without duplicating backups.
# Backups are stored outside active skill scan directories under
# ~/.config/ai-config/backups/<timestamp>/.

REPO_DIR="$(cd "$(dirname "$0")" && pwd -P)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_STAMP="$(date +%Y%m%d%H%M%S)"
BACKUP_ROOT=""
REPO_LINK="$XDG_CONFIG_HOME/ai-config/repo"
WORKSPACE_DIR="$HOME/GitHub"
WORKSPACE_REQUESTED=0
BUILD_BROWSE=0
INSTALL_LAUNCHAGENT=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]
  --workspace DIR       Install shared workspace instructions in DIR
  --with-browse         Install/build the optional Browse daemon using Bun
  --with-launchagent    Register weekly memory rotation with macOS launchd
  --skip-browse         Skip the optional Browse build (default)
  --skip-launchagent    Skip launchd registration (default)
  --help                Show this help

Requires Bash and Python 3.11+. Local overlays and user content are preserved.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { echo "--workspace requires a directory" >&2; exit 2; }
      WORKSPACE_DIR="$2"
      WORKSPACE_REQUESTED=1
      shift 2 ;;
    --with-browse) BUILD_BROWSE=1; shift ;;
    --skip-browse) BUILD_BROWSE=0; shift ;;
    --with-launchagent) INSTALL_LAUNCHAGENT=1; shift ;;
    --skip-launchagent) INSTALL_LAUNCHAGENT=0; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$XDG_CONFIG_HOME" in
  /*) ;;
  *) echo "XDG_CONFIG_HOME must be an absolute path" >&2; exit 2 ;;
esac
if ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import sys, tomllib; assert sys.version_info >= (3, 11)' >/dev/null 2>&1; then
  echo "Install Python 3.11 or later before running install.sh." >&2
  exit 1
fi
if [ "$BUILD_BROWSE" -eq 1 ] && ! command -v bun >/dev/null 2>&1; then
  echo "--with-browse requires Bun on PATH." >&2
  exit 1
fi
if [ "$INSTALL_LAUNCHAGENT" -eq 1 ] && { [ "$(uname -s)" != "Darwin" ] || ! command -v launchctl >/dev/null 2>&1; }; then
  echo "--with-launchagent requires macOS and launchctl." >&2
  exit 1
fi
umask 077

backup_path() {
  local dst="$1"

  if [[ "$dst" == "$HOME/"* ]]; then
    printf '%s/home/%s\n' "$BACKUP_ROOT" "${dst#"$HOME"/}"
  else
    printf '%s/abs/%s\n' "$BACKUP_ROOT" "${dst#/}"
  fi
}

backup_existing() {
  local dst="$1"
  local backup_dst
  if [ -z "$BACKUP_ROOT" ]; then
    mkdir -p "$XDG_CONFIG_HOME/ai-config/backups"
    BACKUP_ROOT="$(mktemp -d "$XDG_CONFIG_HOME/ai-config/backups/$BACKUP_STAMP.XXXXXX")"
  fi
  backup_dst="$(backup_path "$dst")"

  mkdir -p "$(dirname "$backup_dst")"
  mv "$dst" "$backup_dst"
  echo "  ⟳ backed up $dst -> $backup_dst"
}

migrate_stale_skill_backups() {
  local skills_dir="$1" label="$2"
  local found=0

  [ -d "$skills_dir" ] || return 0

  while IFS= read -r -d '' entry; do
    found=1
    backup_existing "$entry"
    echo "  ⟳ migrated stale $label skill backup $(basename "$entry")"
  done < <(find "$skills_dir" -mindepth 1 -maxdepth 1 -name '*.bak-*' -print0)

  if [ "$found" -eq 0 ]; then
    echo "  ✓ no stale $label skill backups"
  fi
}

link() {
  local src="$1" dst="$2"

  # A checkout may itself live at the managed alias path.
  if [ -e "$dst" ] && [ "$src" -ef "$dst" ]; then
    echo "  ✓ $dst (already linked)"
    return
  fi

  # Already correct symlink — skip
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ✓ $dst (already linked)"
    return
  fi

  # Backup existing file/dir/symlink
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup_existing "$dst"
  fi

  # Ensure parent dir exists
  mkdir -p "$(dirname "$dst")"

  ln -s "$src" "$dst"
  echo "  → $dst"
}

copy_if_missing() {
  local src="$1" dst="$2"

  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "  ✓ $dst (already present)"
    return
  fi

  cp "$src" "$dst"
  echo "  + created $dst"
}

link_skill_dirs() {
  local src_dir="$1" dst_dir="$2" label="$3"
  local skill_dir skill_name

  mkdir -p "$dst_dir"
  migrate_stale_skill_backups "$dst_dir" "$label"

  for skill_dir in "$src_dir"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    link "$(cd "$skill_dir" && pwd)" "$dst_dir/$skill_name"
  done
}

echo "Installing ai-config symlinks..."
echo ""
link "$REPO_DIR" "$REPO_LINK"

# ── Claude Code ──
echo "Claude Code:"
link "$REPO_DIR/claude/agents"          "$HOME/.claude/agents"
link "$REPO_DIR/claude/commands"        "$HOME/.claude/commands"
link "$REPO_DIR/claude/uiux-contract"   "$HOME/.claude/uiux-contract"
link "$REPO_DIR/claude/output-styles"   "$HOME/.claude/output-styles"
# Hooks now live in settings.json, which Claude Code loads natively.
if [ -L "$HOME/.claude/hooks.json" ] && [ "$(readlink "$HOME/.claude/hooks.json")" = "$REPO_DIR/claude/hooks.json" ]; then
  rm "$HOME/.claude/hooks.json"
  echo "  ✓ removed obsolete Claude hook symlink"
fi
link "$REPO_DIR/claude/settings.json"   "$HOME/.claude/settings.json"
link "$REPO_DIR/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
link "$REPO_DIR/claude/resources"       "$HOME/.claude/resources"

echo ""
echo "Claude Code skills:"
link_skill_dirs "$REPO_DIR/claude/skills" "$HOME/.claude/skills" "Claude"

copy_if_missing "$REPO_DIR/claude/settings.local.example.json" "$HOME/.claude/settings.local.json"
copy_if_missing "$REPO_DIR/claude/.env.example" "$HOME/.claude/.env"

# USER/ is private runtime content, copied from templates rather than linked.
if [ -d "$REPO_DIR/claude/user" ]; then
  if [ -L "$HOME/.claude/USER" ]; then
    echo "  USER is a symlink; left unchanged. Keep writable context outside the checkout."
  elif [ -e "$HOME/.claude/USER" ] && [ ! -d "$HOME/.claude/USER" ]; then
    echo "  USER is not a directory; left unchanged."
  else
    while IFS= read -r -d '' user_template; do
      copy_if_missing "$user_template" "$HOME/.claude/USER/${user_template#"$REPO_DIR/claude/user/"}"
    done < <(find "$REPO_DIR/claude/user" -type f -print0)
  fi
fi

# ── MEMORY scaffold ──
echo ""
echo "MEMORY:"
"$REPO_DIR/scripts/setup-memory.sh"
echo "  ✓ ~/.claude/MEMORY/ scaffold ready"

# ── Cache directories ──
mkdir -p "$HOME/.cache/ai-statusline"
echo "  ✓ ~/.cache/ai-statusline/ ready"

echo ""

# ── Codex ──
echo "Codex:"
link "$REPO_DIR/codex/agents"           "$HOME/.codex/agents"
link "$REPO_DIR/codex/instructions"     "$HOME/.codex/instructions"
link "$REPO_DIR/codex/workflows"        "$HOME/.codex/workflows"
link "$REPO_DIR/codex/rules"            "$HOME/.codex/rules"
link "$REPO_DIR/codex/hooks.json"       "$HOME/.codex/hooks.json"

echo ""
echo "Codex skills:"
link_skill_dirs "$REPO_DIR/codex/skills" "$HOME/.codex/skills" "Codex"

copy_if_missing "$REPO_DIR/codex/config.local.example.toml" "$XDG_CONFIG_HOME/codex/config.local.toml"
"$REPO_DIR/scripts/render-codex-config.sh"

echo ""

# ── Shared (workspace-level) ──
echo "Shared:"
if [ "$WORKSPACE_REQUESTED" -eq 1 ]; then
  mkdir -p "$WORKSPACE_DIR"
fi
if [ -d "$WORKSPACE_DIR" ]; then
  WORKSPACE_DIR="$(cd "$WORKSPACE_DIR" && pwd -P)"
  link "$REPO_LINK/shared/CLAUDE.md" "$WORKSPACE_DIR/CLAUDE.md"
  link "$WORKSPACE_DIR/CLAUDE.md" "$WORKSPACE_DIR/AGENTS.md"
else
  echo "  Skipped workspace instructions; choose a directory with --workspace DIR."
fi

# ── LaunchAgents ──
echo ""
echo "LaunchAgents:"
plist_src="$REPO_DIR/launchagents/com.ai-config.memory-rotate.plist"
plist_dst="$HOME/Library/LaunchAgents/com.ai-config.memory-rotate.plist"
if [ "$INSTALL_LAUNCHAGENT" -eq 1 ]; then
  mkdir -p "$HOME/Library/LaunchAgents" "$HOME/.cache/ai-config"
  plist_temp="$(mktemp "$XDG_CONFIG_HOME/ai-config/memory-rotate.XXXXXX")"
  python3 - "$plist_src" "$plist_temp" "$REPO_LINK" "$HOME/.cache/ai-config" <<'PY'
from pathlib import Path
import plistlib
import sys

source, temporary, repository, cache = map(Path, sys.argv[1:])
with source.open("rb") as stream:
    job = plistlib.load(stream)
job["ProgramArguments"] = ["/bin/bash", str(repository / "scripts/memory-rotate.sh")]
job["StandardOutPath"] = str(cache / "memory-rotate.log")
job["StandardErrorPath"] = str(cache / "memory-rotate.log")
with temporary.open("wb") as stream:
    plistlib.dump(job, stream)
PY
  launchctl unload "$plist_dst" 2>/dev/null || true
  if [ -e "$plist_dst" ] && ! cmp -s "$plist_temp" "$plist_dst"; then
    backup_existing "$plist_dst"
  fi
  mv "$plist_temp" "$plist_dst"
  launchctl load "$plist_dst"
  echo "  ✓ memory-rotate LaunchAgent (weekly Sunday 3am)"
else
  echo "  Skipped (enable on macOS with --with-launchagent)."
fi

echo ""
echo "Dev scripts:"
link "$REPO_DIR/scripts/dev-verify.sh" "$HOME/.local/bin/dev-verify"
link "$REPO_DIR/scripts/dev-format.sh" "$HOME/.local/bin/dev-format"
link "$REPO_DIR/scripts/dev-status.sh" "$HOME/.local/bin/dev-status"

echo ""
echo "Browse daemon:"
if [ "$BUILD_BROWSE" -eq 1 ]; then
  mkdir -p "$HOME/.browse"
  "$REPO_DIR/scripts/build-browse.sh"
  # Symlink browse and browse-ctl onto PATH
  mkdir -p "$HOME/.local/bin"
  link "$REPO_DIR/scripts/browse-ctl.sh" "$HOME/.local/bin/browse-ctl"
  if [ -x "$REPO_DIR/browse/dist/browse" ]; then
    link "$REPO_DIR/browse/dist/browse" "$HOME/.local/bin/browse"
  fi
else
  echo "  Skipped (enable with --with-browse after installing Bun)."
fi

echo ""
echo "Done."
echo "  Claude base: $REPO_DIR/claude/settings.json"
echo "  Claude local overlay: ~/.claude/settings.local.json"
echo "  Codex base: $REPO_DIR/codex/config.base.toml"
echo "  Codex local overlay: $XDG_CONFIG_HOME/codex/config.local.toml"
