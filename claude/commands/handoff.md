Generate a session handoff document for the current project.

Context (optional): $ARGUMENTS

1. GATHER STATE:
   - Current branch and `git status`
   - Recent commits: `git log --oneline -10`
   - Uncommitted changes: `git diff --stat`
   - Quick verification: `dev-verify --quick` (capture output)
   - TODO/FIXME in recently changed files

2. READ CONTEXT:
   - Project CLAUDE.md (if exists)
   - Existing SESSION_HANDOFF.md in project root (if exists)
   - Project memory in ~/GitHub/.memory/projects/ (if exists)

3. WRITE SESSION_HANDOFF.md in project root:

   ```
   # Session Handoff — YYYY-MM-DD

   ## Completed
   - [bullet list from commits and changes]

   ## Key Files Changed
   - [grouped by area]

   ## Verification State
   - [which checks ran, results]

   ## Remaining / Known Gaps
   - [what's not done, deferred items]

   ## Resume Commands
   - [exact commands to verify state on next session start]

   ## Decisions Made
   - [non-obvious choices and rationale]
   ```

4. JOURNAL:
   - Run ~/GitHub/.memory/scripts/journal.sh with summary

Rules:

- Be factual — only list what actually happened
- Include specific file paths, not vague descriptions
- The handoff must be usable by a different agent with zero prior context
- Overwrite any existing SESSION_HANDOFF.md (it's always for the latest session)
