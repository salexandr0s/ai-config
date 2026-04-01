Systematic root-cause debugging with scope-locking and escalation protocol.

Bug report / symptom: $ARGUMENTS

---

## Phase 1 — Investigate

Collect evidence. **NO fixes yet.**

1. Ask for the minimum info needed to reproduce (≤ 5 questions): expected vs actual, repro steps, environment, recent changes
2. Read relevant code, logs, and error output directly from the repo
3. Check `git log --oneline -20` for recent regressions — correlate timing with when the bug appeared
4. Reproduce the bug if possible — note exact steps and output
5. Map the blast radius: what systems/files/functions are involved?

**Gate:** Do NOT proceed to Phase 2 until you have concrete evidence (error messages, failing test output, or confirmed reproduction).

---

## Phase 2 — Analyze

Form hypotheses based on evidence.

1. Generate 2–4 hypotheses ranked by likelihood
2. For each hypothesis: state the evidence for/against it
3. Pattern-match against known failure modes:
   - Race conditions / timing dependencies
   - Nil/undefined propagation
   - State corruption or stale cache
   - Off-by-one or boundary errors
   - Missing error handling at system boundaries
   - Configuration drift between environments
4. Check `~/.claude/MEMORY/LEARNINGS/what-fails.md` for known patterns matching the symptom
5. If a previous hypothesis was wrong, document what was ruled out before moving to the next

---

## Phase 3 — Hypothesize

Commit to a root cause.

**Iron Law:** No fix without an identified root cause. Fixing symptoms creates new bugs.

1. State the root cause with confidence level: `high`, `medium`, or `low`
2. Note key assumptions and unknowns
3. Describe the proposed fix and why it addresses the root cause (not just the symptom)
4. Propose the fastest experiments to falsify the hypothesis (commands, toggles, logging to add)

**3-Strike Rule:** If 3 hypotheses have been tested and falsified → **STOP** and escalate to the user. Do not continue guessing.

**Gate:** Get user confirmation before proceeding to Phase 4.

---

## Phase 4 — Implement

Fix the root cause with the narrowest reviewer-acceptable change.

1. **Auto-scope-lock:** Write the affected directory to `~/.claude/freeze-dir.txt` to prevent accidental edits elsewhere
2. Write a regression test that **fails before** the fix and **passes after** when practical; if the bug is non-simple and no reproducer is added, explain why
3. Apply the narrowest reviewer-acceptable fix at the root cause — avoid symptom-only band-aids
4. Run the regression test to confirm it passes
5. Run `dev-verify`, or the targeted fallback if no unified verify entrypoint exists, to check for collateral damage

---

## Closeout

1. **Unfreeze:** Delete `~/.claude/freeze-dir.txt`
2. Run `dev-verify` — full verification, or the targeted equivalent if no unified verify entrypoint exists
3. Report status using one of:
   - **DONE** — Root cause identified, fix applied, tests pass, verification passes
   - **DONE_WITH_CONCERNS** — Fixed but with caveats (list each concern)
   - **BLOCKED** — Cannot proceed (state blocker, what was tried, recommendation)

---

## Recovery Patterns

- Check `~/.claude/MEMORY/LEARNINGS/what-fails.md` for known patterns matching the symptom
- If hypothesis was wrong, document what was ruled out before moving to next
- For hard-to-reproduce bugs, propose a bisect strategy: `git bisect` with a test command
- For intermittent failures: look for race conditions, add logging, check for external dependencies

## Pitfalls Check

Before declaring done, verify:
- [ ] Fix addresses root cause, not just the symptom
- [ ] No new `any` types, type suppressions, or weakened checks
- [ ] Regression test actually fails without the fix
- [ ] `dev-verify` passes clean, or targeted fallback validation passes and is reported explicitly
- [ ] Freeze has been removed
