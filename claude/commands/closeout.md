Perform a change closeout — the final quality gate before commit.

Context: $ARGUMENTS

1. REVIEW all changes:
   - Run `git diff --stat` and `git diff` (staged + unstaged)
   - For each changed file: check correctness, style, edge cases, security
   - Categorize findings as BLOCKER (must fix) or WARNING (should fix)

2. FIX issues found:
   - Fix BLOCKERs immediately
   - Fix WARNINGs if the fix is safe and small (<10 lines)
   - Do not expand scope — only fix what's in the diff

3. VERIFY:
   - Run `dev-verify` (full: lint + typecheck + tests)
   - All must pass. If any fail, fix and re-run.
   - Check: no debug prints left, no TODO in new code, no hardcoded secrets

4. COMMIT (with user approval):
   - Stage the changes (specific files, not `git add -A`)
   - Draft commit message: type(scope): description
   - Present to user before committing
   - After commit: `git log --oneline -1` to confirm

5. FEEDBACK CAPTURE:
   - If the user gave explicit feedback during this session (ratings, "great work", "that's wrong"):
     Append to `~/.claude/MEMORY/SIGNALS/ratings.jsonl`:
     `{"timestamp":"...","session_id":"...","score":N,"trigger_phrase":"...","context":"..."}`
   - If sentiment is detectable, append to `~/.claude/MEMORY/SIGNALS/sentiment.jsonl`:
     `{"timestamp":"...","session_id":"...","polarity":"positive|negative|neutral","confidence":"high|medium|low","trigger_phrase":"..."}`

Output a closeout report:

- Changes: files changed with line counts
- Issues: found and fixed (with before/after)
- Verification: pass/fail for each step
- Commit: hash and message (after commit)
- Follow-ups: anything deferred
