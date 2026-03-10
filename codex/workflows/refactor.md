# Safe Refactor Workflow

Use this prompt template for safe, atomic refactoring with Codex multi-agent orchestration.

## Usage

```
codex "Follow the workflow in workflows/refactor.md to refactor: <refactor description>"
```

## Workflow

You are orchestrating a safe refactoring workflow using your available agents. The key principle: every step must leave the codebase in a valid state, and failed steps get reverted, not pushed forward.

### Phase 1: Map Impact

Spawn the **researcher** agent to map the refactoring scope:

- Identify all code affected (direct and indirect)
- Map dependency chains — imports, callers, consumers
- Catalog test coverage for affected areas
- Identify the riskiest parts of the change
- Note external API contracts that must be preserved

Wait for researcher to complete before proceeding.

### Phase 2: Plan Atomic Steps

Spawn the **planner** agent with the researcher's impact report:

- Design strictly atomic steps (each leaves codebase valid)
- Each step must be independently revertable
- Order steps safest-first
- For each step: specify changes, verification command, and revert strategy

Wait for planner to complete before proceeding.

### Phase 3: Review Plan

Spawn the **reviewer** agent to critique the refactoring plan:

- Are steps truly atomic?
- Is ordering safe (dependencies respected)?
- Are any affected areas missing?
- Are revert strategies viable?
- Could any step silently break uncovered code?

**IMPORTANT: Present the reviewed plan to the user and wait for approval before proceeding.**

### Phase 4: Implement (Atomic)

After user approval, spawn the **coder** agent with the approved plan:

- Execute ONE step at a time
- Run `dev-verify` (full, not --quick) after EVERY step
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

If "Must Fix" items found: coder fixes, reviewer re-reviews (max 2 cycles).

### Phase 6: Closeout

- Run full `dev-verify` one final time
- Commit with message: `refactor(scope): description`
- Present summary: what changed, steps completed, any deferred items

## Rules

- Verification after EVERY step, not batched
- On failure: revert, don't push forward
- User approval required between plan review and implementation
- Explorer, planner, and reviewer are read-only
- Max 2 review-fix cycles in final review
- Refactor must NOT change behavior — only structure
