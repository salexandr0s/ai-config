Run a streamlined bugfix workflow: investigate, fix, review, closeout.

Context: $ARGUMENTS

## Why This Workflow

Bugfixes need fast turnaround without sacrificing quality. This workflow still requires a real root cause, explicit confidence, and regression coverage for non-simple fixes before closeout.

## Team Formation

Create a team using `TeamCreate` with:

- **team-lead** (you) — orchestrator, manages phase transitions
- **researcher** — investigates the bug
- **coder** — fixes the bug
- **reviewer** — validates the fix

## Phase 1: Investigate

Assign to: `researcher`

Task: Track down the bug described in the context:

- Reproduce or confirm the bug's existence from code analysis
- Trace the execution path to find the root cause
- Identify all files involved (not just the symptom location)
- Check for related issues — same pattern elsewhere?
- Note existing test coverage for the affected area
- State whether this is a simple or non-simple bug under the Bug Handling rules

Handover to team-lead: investigation report with root cause, confidence level, affected files (file:line), reproduction steps, and testing implications.

Gate: team-lead confirms root cause is identified.

## Phase 2: Fix

Assign to: `coder`

Input: researcher's investigation report.

Task:

1. Write a mini-plan (3-5 lines) describing the fix approach — include in your first message
2. Re-read files before changing them, and re-read them after each change to confirm the applied edits
3. Implement the fix at the root cause, not just the symptom
4. Add or update tests to cover the bug scenario; if the bug is non-simple and no reproducer is added, explain why
5. Run `dev-verify --quick` after changes, or the targeted fallback if no unified verify entrypoint exists
6. Verify the fix addresses the original bug description
7. State confidence in the final fix (`high`, `medium`, or `low`) with any key assumptions

Handover to team-lead: fix complete, mini-plan summary, verification status, confidence, and test coverage summary.

Gate: verification or explicit targeted fallback passes.

## Phase 3: Review

Assign to: `reviewer`

Input: coder's changes + investigation report.

Task: Validate the fix:

- Confirm fix addresses root cause (not just symptom)
- Check for regressions or side effects
- Verify test coverage for the bug scenario
- Assess code quality of the fix
- Check mechanical-safety compliance where relevant
- Produce report: Must Fix / Should Fix / Nits / Verdict

Handover to team-lead: review report.

Gate: review verdict. If "Must Fix" items exist, enter fix cycle. If clean, proceed to Phase 4.

**Fix cycle (max 2 iterations):**

1. Coder addresses "Must Fix" and "Should Fix" items
2. Coder runs `dev-verify --quick` or the targeted fallback if needed
3. Reviewer re-reviews changed areas
4. If still "Must Fix" items after 2 iterations → **STOP** and escalate to user

## Phase 4: Closeout

Assign to: team-lead

Task:

1. Run full `dev-verify` (lint + typecheck + tests), or the targeted equivalent if no unified verify entrypoint exists
2. Verify the fix addresses the original bug
3. Commit changes with conventional message: `fix(scope): description`
4. Present summary to user: root cause, confidence, what was fixed, tests added

## Rules

- No user approval gate — trust the review phase to catch issues
- Maximum 2 review-fix cycles — escalate after that
- Coder **MUST** write a mini-plan before implementing
- Coder **MUST** add tests covering the bug scenario when practical
- Fix the root cause, not the symptom
- If the bug cannot be reproduced or root cause is unclear, ask the user before proceeding
