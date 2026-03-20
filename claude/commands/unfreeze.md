Remove the directory edit restriction.

1. Check if `~/.claude/freeze-dir.txt` exists
2. If it exists:
   - Read it to show which directory was frozen
   - Delete `~/.claude/freeze-dir.txt`
   - Confirm: "Edit restriction removed. Was locked to {dir}."
3. If it doesn't exist:
   - Confirm: "No freeze active — edits are unrestricted."
