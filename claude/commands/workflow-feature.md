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

## Phase 1: Research

Assign to: `researcher`

Task: Explore the codebase to understand the area affected by this feature:

- Map relevant architecture, files, and dependencies
- Identify existing patterns and conventions to follow
- Find related tests and coverage
- Flag risks, unknowns, and potential conflicts
- Note any existing code that can be reused

Handover to team-lead: structured exploration report with file:line references.

Gate: team-lead confirms exploration covers the feature scope.

## Phase 2: Plan

Assign to: `planner`

Input: researcher's exploration report + original context.

Task: Design the implementation plan:

- Summary of approach
- Files to create or modify (with rationale)
- Numbered implementation steps (small, verifiable)
- Testing strategy (unit, integration, E2E as appropriate)
- Edge cases and error handling considerations
- Risks and mitigations

Handover to team-lead: structured implementation plan.

Gate: team-lead presents plan to user. **MUST get user approval before proceeding to Phase 3.**

## Phase 3: Implement

Assign to: `coder`

Input: approved plan from Phase 2.

Task: Execute the plan step-by-step:

- Follow the plan's steps in order
- Match existing project patterns and conventions
- Run `dev-verify --quick` every 3-5 file changes
- Report blockers immediately — do not silently struggle
- Stay within plan scope — flag any needed deviations to team-lead

Handover to team-lead: implementation complete, verification status.

Gate: `dev-verify --quick` passes.

## Phase 4: Review

Assign to: `reviewer`

Input: coder's changes + original plan.

Task: Review the implementation:

- Check implementation matches the approved plan
- Assess correctness, security, performance, and quality
- Verify test coverage for new functionality
- Check for convention violations (consult CLAUDE.md)
- Produce report: Must Fix / Should Fix / Nits / Verdict

Handover to team-lead: review report.

Gate: review verdict. If "Must Fix" items exist, proceed to Phase 5. If clean, skip to Phase 6.

## Phase 5: Fix Cycle (max 3 iterations)

Assign to: `coder` (fix) then `reviewer` (re-review)

For each iteration:

1. Coder addresses all "Must Fix" and "Should Fix" items
2. Coder runs `dev-verify --quick`
3. Reviewer re-reviews only the changed areas
4. If new "Must Fix" items → next iteration
5. If clean → proceed to Phase 6

If 3 iterations exhausted with remaining "Must Fix" items → **STOP** and escalate to user.

## Phase 6: Closeout

Assign to: team-lead

Task:

1. Run full `dev-verify` (lint + typecheck + tests)
2. Verify all tasks are complete
3. Commit changes with conventional message format
4. Present summary to user: what was built, files changed, any deferred items

## Rules

- User approval is **REQUIRED** between Phase 2 (Plan) and Phase 3 (Implement)
- Maximum 3 review-fix cycles — escalate after that
- Coder **MUST** run `dev-verify --quick` every 3-5 file changes
- All agents **MUST** use `SendMessage` for handovers, not broadcast
- Scope changes **MUST** be flagged to user — never silently expand
- If context is unclear from $ARGUMENTS, ask the user before starting
