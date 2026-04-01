<!-- Source of truth: claude/commands/workflow-refactor.md — keep phases and rules in sync -->

# Safe Refactor Workflow

Use this prompt template for safe, atomic refactoring with Codex multi-agent orchestration.

## Usage

```
codex "Follow the workflow in workflows/refactor.md to refactor: <refactor description>"
```

## Workflow

You are orchestrating a safe refactoring workflow using your available agents. The key principle: every step must leave the codebase in a valid state, and failed steps get reverted, not pushed forward.

If the refactor touches more than 5 independent files, split it into explicit phases or parallel owners before implementation.

### Phase 1: Map Impact

Spawn the **researcher** agent to map the refactoring scope:

- Identify all code affected (direct and indirect)
- Map dependency chains — imports, callers, consumers
- Catalog test coverage for affected areas
- Identify the riskiest parts of the change
- Note external API contracts that must be preserved
- Flag files over 300 LOC that require Step 0 cleanup before structural refactoring
- Flag any rename/signature-change search surface beyond direct refs

Wait for researcher to complete before proceeding.

### Phase 2: Plan Atomic Steps

Spawn the **planner** agent with the researcher's impact report:

- Design strictly atomic steps (each leaves codebase valid)
- Each step must be independently revertable
- Order steps safest-first
- Keep each phase bounded to 5 independent files or less, or define disjoint parallel ownership
- Insert a dedicated Step 0 cleanup phase before any structural refactor on a file over 300 LOC
- Specify the targeted fallback verification if `dev-verify` is unavailable for the repo shape
- For each step: specify changes, verification command, and revert strategy

Wait for planner to complete before proceeding.

### Phase 3: Review Plan

Spawn the **reviewer** agent to critique the refactoring plan:

- Are steps truly atomic?
- Is ordering safe (dependencies respected)?
- Are any affected areas missing?
- Are revert strategies viable?
- Is Step 0 cleanup present where needed?
- Are rename/signature-change searches broad enough?
- Could any step silently break uncovered code?

**IMPORTANT: Present the reviewed plan to the user and wait for approval before proceeding.**

### Phase 4: Implement (Atomic)

After user approval, spawn the **coder** agent with the approved plan:

- Re-read files before changing them, and re-read them again after each change to confirm the applied edit
- Execute ONE step at a time
- Run `dev-verify` (full, not --quick) after EVERY step, or the plan's targeted fallback if needed
- If verification passes: proceed to next step
- If verification fails: REVERT the step immediately, confirm clean state, report failure
- Do NOT fix forward — revert and report

**Critical: verify after every single step, not batched.**

### Phase 5: Final Review

Spawn the **reviewer** agent to review the complete refactoring:

- Confirm behavior is preserved (no functional changes)
- Check for missed references or dangling imports
- Verify naming consistency
- Confirm tests still cover refactored paths
- Check mechanical-safety compliance where relevant

If "Must Fix" items found: coder fixes, reviewer re-reviews (max 2 cycles).

### Phase 6: Closeout

- Run full `dev-verify` one final time, or the targeted equivalent if no unified verify entrypoint exists
- Commit with message: `refactor(scope): description`
- Present summary: what changed, steps completed, any deferred items

## Rules

- Verification after EVERY step, not batched
- On failure: revert, don't push forward
- User approval required between plan review and implementation
- Explorer, planner, and reviewer are read-only
- Max 2 review-fix cycles in final review
- Refactor must NOT change behavior — only structure
