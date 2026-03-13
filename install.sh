#!/usr/bin/env bash
set -euo pipefail

# ai-config installer — creates symlinks from tool config dirs to this repo
# Usage: ./install.sh
#
# Safe: backs up existing files/dirs before overwriting.
# Idempotent: re-running updates symlinks without duplicating backups.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX=".bak-$(date +%Y%m%d%H%M%S)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

link() {
  local src="$1" dst="$2"

  # Already correct symlink — skip
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ✓ $dst (already linked)"
    return
  fi

  # Backup existing file/dir/symlink
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "${dst}${BACKUP_SUFFIX}"
    echo "  ⟳ backed up $dst"
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

echo "Installing ai-config symlinks..."
echo ""

# ── Claude Code ──
echo "Claude Code:"
link "$REPO_DIR/claude/agents"          "$HOME/.claude/agents"
link "$REPO_DIR/claude/commands"        "$HOME/.claude/commands"
link "$REPO_DIR/claude/uiux-contract"   "$HOME/.claude/uiux-contract"
link "$REPO_DIR/claude/output-styles"   "$HOME/.claude/output-styles"
link "$REPO_DIR/claude/hooks.json"      "$HOME/.claude/hooks.json"
link "$REPO_DIR/claude/settings.json"   "$HOME/.claude/settings.json"
link "$REPO_DIR/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

# Skills: link individual items (shadcn may be managed separately)
mkdir -p "$HOME/.claude/skills"
link "$REPO_DIR/claude/skills/visual-explainer" "$HOME/.claude/skills/visual-explainer"
copy_if_missing "$REPO_DIR/claude/settings.local.example.json" "$HOME/.claude/settings.local.json"

echo ""

# ── Codex ──
echo "Codex:"
link "$REPO_DIR/codex/agents"           "$HOME/.codex/agents"
link "$REPO_DIR/codex/instructions"     "$HOME/.codex/instructions"
link "$REPO_DIR/codex/rules"            "$HOME/.codex/rules"
mkdir -p "$HOME/.codex/skills"
link "$REPO_DIR/codex/skills/config-editor" "$HOME/.codex/skills/config-editor"
copy_if_missing "$REPO_DIR/codex/config.local.example.toml" "$XDG_CONFIG_HOME/codex/config.local.toml"
"$REPO_DIR/scripts/render-codex-config.sh"

echo ""

# ── Shared (workspace-level) ──
echo "Shared:"
GITHUB_DIR="$HOME/GitHub"
if [ -d "$GITHUB_DIR" ]; then
  # Use relative symlink so it works if ~/GitHub moves
  cd "$GITHUB_DIR"
  link "ai-config/shared/CLAUDE.md" "$GITHUB_DIR/CLAUDE.md"

  # AGENTS.md → CLAUDE.md (standard alias)
  if [ ! -L "$GITHUB_DIR/AGENTS.md" ]; then
    link "CLAUDE.md" "$GITHUB_DIR/AGENTS.md"
  else
    echo "  ✓ $GITHUB_DIR/AGENTS.md (already linked)"
  fi
  cd - > /dev/null
else
  echo "  ⚠ ~/GitHub not found — skipping shared CLAUDE.md"
fi

echo ""
echo "Done."
echo "  Claude base: $REPO_DIR/claude/settings.json"
echo "  Claude local overlay: ~/.claude/settings.local.json"
echo "  Codex base: $REPO_DIR/codex/config.base.toml"
echo "  Codex local overlay: $XDG_CONFIG_HOME/codex/config.local.toml"
