Generate a session handoff document and close the session.

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

4. CLOSE SESSION — **MUST** run this command after writing the handoff:

   ```bash
   ~/GitHub/.memory/scripts/session-end.sh "<tool>" "<project>" "<one-line summary>"
   ```

   Where:
   - `<tool>` = `claude-code`, `codex`, or `openclaw`
   - `<project>` = project directory name (lowercase)
   - `<summary>` = one sentence describing what was accomplished

   This writes the journal entry and syncs the memory index. **Do NOT skip this step.**

Rules:

- Be factual — only list what actually happened
- Include specific file paths, not vague descriptions
- The handoff must be usable by a different agent with zero prior context
- Overwrite any existing SESSION_HANDOFF.md (it's always for the latest session)
- Step 4 is mandatory — a handoff without a journal entry is incomplete
