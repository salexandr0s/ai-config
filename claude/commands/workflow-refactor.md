Run a safe refactoring workflow with atomic steps and verification after every change.

Context: $ARGUMENTS

## Why This Workflow

Refactors are high-risk — they change structure without changing behavior, so regressions are silent. This workflow enforces atomic steps with verification after EVERY step (not every 3-5), reviewer approval of the plan before implementation, and automatic revert on failure.

## Team Formation

Create a team using `TeamCreate` with:

- **team-lead** (you) — orchestrator, enforces atomic discipline
- **researcher** — maps impact and dependencies
- **planner** — designs atomic refactoring steps
- **reviewer** — reviews plan AND code (used twice)
- **coder** — executes atomic steps

## Phase 1: Map Impact

Assign to: `researcher`

Task: Thoroughly map the refactoring scope:

- Identify all code affected by the refactor (direct and indirect)
- Map dependency chains — what imports/uses the code being changed?
- List all consumers, callers, and dependents
- Catalog existing test coverage for affected areas
- Identify the riskiest parts of the change
- Note any external API contracts that must be preserved

Handover to team-lead: impact report with complete dependency map and file:line references.

Gate: team-lead confirms impact analysis is thorough.

## Phase 2: Plan Atomic Steps

Assign to: `planner`

Input: researcher's impact report.

Task: Design a refactoring plan with strictly atomic steps:

- Each step **MUST** leave the codebase in a valid, passing state
- Each step **MUST** be independently revertable
- Order steps to minimize risk (safest first)
- For each step, specify:
  - What changes
  - Why this order
  - What to verify after
  - How to revert if verification fails

Output format:

```
## Refactoring Plan

### Summary
[1-2 sentences]

### Steps
1. [Step name]
   - Changes: [files and what changes]
   - Verify: [specific check command]
   - Revert: [how to undo if verify fails]

2. [Step name]
   ...

### Risks
- [risk and mitigation]
```

Handover to team-lead: atomic refactoring plan.

## Phase 3: Review Plan

Assign to: `reviewer`

Input: planner's refactoring plan + researcher's impact report.

Task: Critique the refactoring plan:

- Are steps truly atomic? (Each leaves codebase valid?)
- Is the ordering safe? (Dependencies respected?)
- Are any affected areas missing from the plan?
- Are revert strategies viable?
- Could any step silently break something not covered by tests?

Produce report: Must Fix / Should Fix / Observations / Verdict on plan quality.

Handover to team-lead: plan review report.

Gate: team-lead presents reviewed plan to user. **MUST get user approval before proceeding to Phase 4.**

## Phase 4: Implement (Atomic Execution)

Assign to: `coder`

Input: approved refactoring plan.

Task: Execute the plan one step at a time with verification after EVERY step:

For each step in the plan:

1. Implement the step's changes
2. Run `dev-verify` (full, not --quick) immediately
3. If verification **passes** → report success, proceed to next step
4. If verification **fails** → **STOP immediately**:
   - Revert the step using the plan's revert strategy
   - Run `dev-verify` again to confirm clean revert
   - Report the failure and what went wrong to team-lead
   - Do NOT attempt to fix forward — wait for team-lead decision

**Critical rule: verify after EVERY step, not every 3-5.**

Handover to team-lead: step-by-step execution log with verification results.

Gate: all steps complete and verified, OR failure reported with clean revert.

## Phase 5: Review Code

Assign to: `reviewer`

Input: coder's completed changes (all steps).

Task: Final review of the complete refactoring:

- Confirm behavior is preserved (no functional changes)
- Check for missed references or dangling imports
- Verify naming consistency across the refactored code
- Confirm test coverage still passes and covers refactored paths
- Produce report: Must Fix / Should Fix / Nits / Verdict

Handover to team-lead: code review report.

Gate: review verdict. If "Must Fix" items exist, coder fixes and reviewer re-reviews (max 2 cycles). If clean, proceed to Phase 6.

## Phase 6: Closeout

Assign to: team-lead

Task:

1. Run full `dev-verify` one final time
2. Verify no behavioral changes were introduced
3. Commit changes with conventional message: `refactor(scope): description`
4. Present summary to user: what was refactored, steps completed, any deferred items

## Rules

- Verification runs after **EVERY** step — not batched
- On verification failure: **revert the step**, do not push forward
- User approval is **REQUIRED** between Phase 3 (Review Plan) and Phase 4 (Implement)
- Maximum 2 review-fix cycles in Phase 5
- Coder **MUST NOT** combine multiple plan steps into one change
- If a revert fails, **STOP** everything and escalate to user immediately
- The refactor **MUST NOT** change behavior — only structure
