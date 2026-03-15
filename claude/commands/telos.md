Review and update your TELOS identity files interactively.

Context: $ARGUMENTS

TELOS files live in `~/.claude/USER/` and define who you are, what you're working on, and how you think.

1. READ all TELOS files:
   - ~/.claude/USER/MISSION.md
   - ~/.claude/USER/GOALS.md
   - ~/.claude/USER/PROJECTS.md
   - ~/.claude/USER/BELIEFS.md
   - ~/.claude/USER/MODELS.md
   - ~/.claude/USER/STRATEGIES.md
   - ~/.claude/USER/NARRATIVES.md
   - ~/.claude/USER/LEARNED.md
   - ~/.claude/USER/CHALLENGES.md
   - ~/.claude/USER/IDEAS.md

2. PRESENT each file's Active section as a numbered list.

3. For each file, ASK:
   - Any items to add?
   - Any items to archive (move to Archived with today's date)?
   - Any items to edit?
   - Skip (press enter)?

4. APPLY changes with user approval:
   - Update the "Last updated" date to today
   - Move archived items with date annotation: `- [YYYY-MM-DD] item text`
   - Add new items to Active section

5. SUMMARY: Show what changed across all files.

Rules:
- Never modify TELOS files without explicit user approval for each change
- Preserve existing content exactly — only add, archive, or edit as directed
- If a file doesn't exist, offer to create it with the standard template
- If $ARGUMENTS specifies a single file (e.g., "goals"), only review that file
