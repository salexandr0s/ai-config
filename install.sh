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
link "$REPO_DIR/claude/resources"       "$HOME/.claude/resources"

# Skills: link individual items (shadcn may be managed separately)
mkdir -p "$HOME/.claude/skills"
link "$REPO_DIR/claude/skills/visual-explainer" "$HOME/.claude/skills/visual-explainer"
link "$REPO_DIR/claude/skills/repo-surgeon"    "$HOME/.claude/skills/repo-surgeon"
link "$REPO_DIR/claude/skills/browse"        "$HOME/.claude/skills/browse"

# Impeccable design skills (bundled in ai-config)
IMPECCABLE_SKILLS=(adapt animate arrange auditui bolder clarify colorize critique delight distill extract frontend-design harden normalize onboard optimize overdrive polish quieter teach-impeccable typeset)
echo ""
echo "Design skills (Claude Code):"
for skill_name in "${IMPECCABLE_SKILLS[@]}"; do
  if [ -d "$REPO_DIR/claude/skills/$skill_name" ]; then
    link "$REPO_DIR/claude/skills/$skill_name" "$HOME/.claude/skills/$skill_name"
  fi
done

# iOS Simulator skill (from sibling repo ~/GitHub/ios-simulator-skill)
IOS_SIM_DIR="$REPO_DIR/../ios-simulator-skill"
if [ -d "$IOS_SIM_DIR/ios-simulator-skill" ]; then
  echo ""
  echo "iOS Simulator Skill (Claude Code):"
  link "$(cd "$IOS_SIM_DIR/ios-simulator-skill" && pwd)" "$HOME/.claude/skills/ios-simulator-skill"
else
  echo "  ⚠ ios-simulator-skill repo not found — skipping"
fi

# Platform Design Skills — HIG rules (from sibling repo ~/GitHub/platform-design-skills)
PLATFORM_DESIGN_DIR="$REPO_DIR/../platform-design-skills"
if [ -d "$PLATFORM_DESIGN_DIR/skills" ]; then
  echo ""
  echo "Platform Design Skills (Claude Code):"
  for skill_dir in "$PLATFORM_DESIGN_DIR"/skills/*/; do
    skill_name="$(basename "$skill_dir")"
    # Prefix with "hig-" to namespace (e.g., hig-ios, hig-macos)
    link "$(cd "$skill_dir" && pwd)" "$HOME/.claude/skills/hig-$skill_name"
  done
else
  echo "  ⚠ platform-design-skills repo not found — skipping"
fi

copy_if_missing "$REPO_DIR/claude/settings.local.example.json" "$HOME/.claude/settings.local.json"
copy_if_missing "$REPO_DIR/claude/.env.example" "$HOME/.claude/.env"

# USER/ directory: copy if missing (preserve user content on upgrade)
if [ -d "$REPO_DIR/claude/user" ]; then
  if [ ! -e "$HOME/.claude/USER" ] && [ ! -L "$HOME/.claude/USER" ]; then
    cp -r "$REPO_DIR/claude/user" "$HOME/.claude/USER"
    echo "  + created ~/.claude/USER/ (TELOS identity files)"
  else
    echo "  ✓ ~/.claude/USER/ (already present — preserved)"
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
link "$REPO_DIR/codex/rules"            "$HOME/.codex/rules"
mkdir -p "$HOME/.codex/skills"
link "$REPO_DIR/codex/skills/config-editor"  "$HOME/.codex/skills/config-editor"
link "$REPO_DIR/codex/skills/repo-surgeon"  "$HOME/.codex/skills/repo-surgeon"
link "$REPO_DIR/codex/skills/browse"         "$HOME/.codex/skills/browse"

# Impeccable design skills for Codex (bundled in ai-config)
echo ""
echo "Design skills (Codex):"
for skill_name in "${IMPECCABLE_SKILLS[@]}"; do
  if [ -d "$REPO_DIR/codex/skills/$skill_name" ]; then
    link "$REPO_DIR/codex/skills/$skill_name" "$HOME/.codex/skills/$skill_name"
  fi
done

# iOS Simulator skill for Codex
if [ -d "$IOS_SIM_DIR/ios-simulator-skill" ]; then
  echo ""
  echo "iOS Simulator Skill (Codex):"
  link "$(cd "$IOS_SIM_DIR/ios-simulator-skill" && pwd)" "$HOME/.codex/skills/ios-simulator-skill"
else
  echo "  ⚠ ios-simulator-skill repo not found — skipping"
fi

# Platform Design Skills for Codex
if [ -d "$PLATFORM_DESIGN_DIR/skills" ]; then
  echo ""
  echo "Platform Design Skills (Codex):"
  for skill_dir in "$PLATFORM_DESIGN_DIR"/skills/*/; do
    skill_name="$(basename "$skill_dir")"
    link "$(cd "$skill_dir" && pwd)" "$HOME/.codex/skills/hig-$skill_name"
  done
else
  echo "  ⚠ platform-design-skills repo not found — skipping"
fi

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

# ── LaunchAgents ──
echo ""
echo "LaunchAgents:"
mkdir -p "$HOME/Library/LaunchAgents"
plist_src="$REPO_DIR/launchagents/com.ai-config.memory-rotate.plist"
plist_dst="$HOME/Library/LaunchAgents/com.ai-config.memory-rotate.plist"
if [ -f "$plist_src" ]; then
  launchctl unload "$plist_dst" 2>/dev/null || true
  sed "s|\$HOME|$HOME|g" "$plist_src" > "$plist_dst"
  launchctl load "$plist_dst" 2>/dev/null || true
  echo "  ✓ memory-rotate LaunchAgent (weekly Sunday 3am)"
fi

echo ""
echo "Dev scripts:"
link "$REPO_DIR/scripts/dev-verify.sh" "$HOME/.local/bin/dev-verify"
link "$REPO_DIR/scripts/dev-format.sh" "$HOME/.local/bin/dev-format"
link "$REPO_DIR/scripts/dev-status.sh" "$HOME/.local/bin/dev-status"

echo ""
echo "Browse daemon:"
mkdir -p "$HOME/.browse"
if command -v bun >/dev/null 2>&1; then
  "$REPO_DIR/scripts/build-browse.sh"
  # Symlink browse and browse-ctl onto PATH
  mkdir -p "$HOME/.local/bin"
  link "$REPO_DIR/scripts/browse-ctl.sh" "$HOME/.local/bin/browse-ctl"
  if [ -x "$REPO_DIR/browse/dist/browse" ]; then
    link "$REPO_DIR/browse/dist/browse" "$HOME/.local/bin/browse"
  fi
else
  echo "  ⚠ Bun not found — browse daemon not compiled."
  echo "    Install Bun (https://bun.sh) then re-run install.sh"
  echo "    Note: browse and browse-ctl will not be on PATH until compiled."
fi

echo ""
echo "Done."
echo "  Claude base: $REPO_DIR/claude/settings.json"
echo "  Claude local overlay: ~/.claude/settings.local.json"
echo "  Codex base: $REPO_DIR/codex/config.base.toml"
echo "  Codex local overlay: $XDG_CONFIG_HOME/codex/config.local.toml"
