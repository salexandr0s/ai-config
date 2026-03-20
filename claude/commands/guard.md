Maximum safety mode: destructive command warnings + directory edit lock.

$ARGUMENTS

1. If $ARGUMENTS specifies a directory:
   - Resolve to absolute path and write to `~/.claude/freeze-dir.txt`
   - Confirm freeze is active
2. If no $ARGUMENTS:
   - Ask which directory to restrict edits to
   - Resolve and write to `~/.claude/freeze-dir.txt`
3. Remind the user that destructive Bash commands will trigger pre-bash-guard warnings (production deployments, infrastructure mutations, database schema changes, destructive git operations)
4. Confirm both protections are active:
   - "Guard mode active:"
   - "  - Edits locked to {dir}"
   - "  - Destructive commands will trigger warnings/blocks"
   - "Use /unfreeze to remove the edit lock."
