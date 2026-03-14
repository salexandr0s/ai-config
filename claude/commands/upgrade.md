Self-update the ai-config repository and reinstall symlinks.

1. Check for dirty working tree in ~/GitHub/ai-config. If dirty, warn and ask to proceed or stash first.
2. Pull latest: `cd ~/GitHub/ai-config && git pull origin main`
3. Run installer: `./install.sh`
4. Show what changed: `git log --oneline -10`
5. Verify key symlinks resolve:
   - `ls -la ~/.claude/commands/` (should be symlink)
   - `ls -la ~/.claude/agents/` (should be symlink)
   - `ls -la ~/.claude/hooks.json` (should be symlink)
   - `ls -la ~/.claude/settings.json` (should be symlink)
6. Report: updated successfully, list of recent changes, any broken symlinks found
