Run a full feature development workflow from research through closeout.

Context: $ARGUMENTS

## Why This Workflow

Features need thorough understanding before implementation. This workflow ensures we research first, plan with user approval, implement cleanly, and review before closing out. The approval gate between planning and implementation prevents wasted work on wrong approaches.

## Team Formation

Create a team using `TeamCreate` with:

- **team-lead** (you) — orchestrator, manages phase transitions and gates
- **researcher** — codebase exploration and context gathering
- **planner** — designs implementation approach
- **coder** — implements the approved plan
- **reviewer** — reviews implementation quality

If the planned work touches more than 5 independent files, the team-lead **MUST** split it into explicit phases or parallel owners before Phase 3.

## Phase 1: Research

Assign to: `researcher`

Task: Explore the codebase to understand the area affected by this feature:

- Map relevant architecture, files, and dependencies
- Identify existing patterns and conventions to follow
- Find related tests and coverage
- Flag risks, unknowns, and potential conflicts
- Note any existing code that can be reused
- Flag whether the scope exceeds 5 independent files or needs rename/signature-change search coverage

Handover to team-lead: structured exploration report with file:line references.

Gate: team-lead confirms exploration covers the feature scope.

## Phase 2: Plan

Assign to: `planner`

Input: researcher's exploration report + original context.

Task: Design the implementation plan:

- Summary of approach
- Files to create or modify (with rationale)
- Numbered implementation steps or phases (small, verifiable)
- Testing strategy (unit, integration, E2E as appropriate)
- Edge cases and error handling considerations
- Risks and mitigations
- Explicit parallelization plan if work exceeds 5 independent files
- Explicit fallback verification plan if `dev-verify` is unavailable for the repo shape
- Explicit rename/signature-change search plan when relevant

Handover to team-lead: structured implementation plan.

Gate: team-lead presents plan to user. **MUST get user approval before proceeding to Phase 3.**

## Phase 3: Implement

Assign to: `coder`

Input: approved plan from Phase 2.

Task: Execute the plan step-by-step:

- Follow the plan's steps in order
- Match existing project patterns and conventions
- Before every edit, re-read the file; after every edit, read it again to confirm the applied change
- After 10+ messages or any long pause, re-read files before editing
- Run `dev-verify --quick` every 3-5 file changes, or the plan's targeted fallback if no unified verify entrypoint exists
- Report blockers immediately — do not silently struggle
- Stay within plan scope for straightforward work, but do not preserve reviewer-visible structural issues on refactor or AI-config style tasks
- If multiple owners were planned, keep ownership disjoint

Handover to team-lead: implementation complete, verification status.

Gate: verification or explicit targeted fallback passes.

## Phase 4: Review

Assign to: `reviewer`

Input: coder's changes + original plan.

Task: Review the implementation:

- Check implementation matches the approved plan
- Assess correctness, security, performance, and quality
- Verify test coverage for new functionality
- Check for convention violations (consult CLAUDE.md)
- Check mechanical-safety compliance where relevant (bounded phases, rename search coverage, explicit verification)
- Produce report: Must Fix / Should Fix / Nits / Verdict

Handover to team-lead: review report.

Gate: review verdict. If "Must Fix" items exist, proceed to Phase 5. If clean, skip to Phase 6.

## Phase 5: Fix Cycle (max 3 iterations)

Assign to: `coder` (fix) then `reviewer` (re-review)

For each iteration:

1. Coder addresses all "Must Fix" and "Should Fix" items
2. Coder runs `dev-verify --quick` or the targeted fallback if needed
3. Reviewer re-reviews only the changed areas
4. If new "Must Fix" items → next iteration
5. If clean → proceed to Phase 6

If 3 iterations exhausted with remaining "Must Fix" items → **STOP** and escalate to user.

## Phase 6: Closeout

Assign to: team-lead

Task:

1. Run full `dev-verify` (lint + typecheck + tests), or the targeted equivalent if no unified verify entrypoint exists
2. Verify all tasks are complete
3. Commit changes with conventional message format
4. Present summary to user: what was built, files changed, any deferred items

## Rules

- User approval is **REQUIRED** between Phase 2 (Plan) and Phase 3 (Implement)
- Maximum 3 review-fix cycles — escalate after that
- Coder **MUST** run `dev-verify --quick` every 3-5 file changes unless the plan defines a tighter cadence
- Work touching more than 5 independent files **MUST** be split into phases or parallel owners with disjoint ownership
- All agents **MUST** use `SendMessage` for handovers, not broadcast
- Scope changes **MUST** be flagged to user — never silently expand
- If context is unclear from $ARGUMENTS, ask the user before starting
