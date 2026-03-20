Restrict file edits to a specific directory for this session.

$ARGUMENTS

1. If no $ARGUMENTS provided, ask which directory to restrict to
2. Resolve the directory to an absolute path: `cd "$DIR" && pwd`
3. Verify the directory exists
4. Write the absolute path to `~/.claude/freeze-dir.txt`
5. Confirm: "Edits locked to {dir}. Use /unfreeze to remove."

Notes:
- The PreToolUse hook (check-freeze.sh) enforces this — Edit and Write calls for files outside this directory will be blocked
- This is a session-level safety measure, not persistent across sessions
- The freeze file is automatically cleaned up by /investigate closeout
