#!/usr/bin/env bash
set -euo pipefail

# ai-config installer — creates symlinks from tool config dirs to this repo
# Usage: ./install.sh
#
# Safe: backs up existing files/dirs before overwriting.
# Idempotent: re-running updates symlinks without duplicating backups.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX=".bak-$(date +%Y%m%d%H%M%S)"

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

echo "Installing ai-config symlinks..."
echo ""

# ── Claude Code ──
echo "Claude Code:"
link "$REPO_DIR/claude/agents"          "$HOME/.claude/agents"
link "$REPO_DIR/claude/commands"        "$HOME/.claude/commands"
link "$REPO_DIR/claude/uiux-contract"   "$HOME/.claude/uiux-contract"
link "$REPO_DIR/claude/hooks.json"      "$HOME/.claude/hooks.json"

# Skills: link individual items (shadcn may be managed separately)
mkdir -p "$HOME/.claude/skills"
link "$REPO_DIR/claude/skills/visual-explainer" "$HOME/.claude/skills/visual-explainer"

echo ""

# ── Codex ──
echo "Codex:"
link "$REPO_DIR/codex/agents"           "$HOME/.codex/agents"
link "$REPO_DIR/codex/rules"            "$HOME/.codex/rules"
mkdir -p "$HOME/.codex/skills"
link "$REPO_DIR/codex/skills/config-editor" "$HOME/.codex/skills/config-editor"

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
echo "Done. Example configs (not symlinked — copy and customize):"
echo "  $REPO_DIR/claude/settings.example.json  →  ~/.claude/settings.json"
echo "  $REPO_DIR/claude/mcp.example.json       →  ~/.claude/.mcp.json"
echo "  $REPO_DIR/codex/config.example.toml     →  ~/.codex/config.toml"
