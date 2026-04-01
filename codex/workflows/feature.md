<!-- Source of truth: claude/commands/workflow-feature.md — keep phases and rules in sync -->

# Feature Development Workflow

Use this prompt template when building a new feature with Codex multi-agent orchestration.

## Usage

```
codex "Follow the workflow in workflows/feature.md to implement: <feature description>"
```

## Workflow

You are orchestrating a feature development workflow using your available agents. Follow these phases in order.

If the planned work touches more than 5 independent files, split it into explicit phases or parallel owners before implementation.

### Phase 1: Explore

Spawn the **researcher** agent to investigate the codebase:

- Map the architecture and files relevant to this feature
- Identify patterns, conventions, and dependencies
- Find existing code that can be reused
- Flag risks and unknowns
- Flag whether the scope exceeds 5 independent files or needs rename/signature-change search coverage

Wait for researcher to complete before proceeding.

### Phase 2: Plan

Spawn the **planner** agent with the researcher's findings:

- Design an implementation plan with numbered steps or phases
- Identify all files to create or modify
- Define testing strategy and edge cases
- Assess risks and mitigations
- Define explicit parallel ownership if work exceeds 5 independent files
- Define explicit fallback verification if `dev-verify` is unavailable for the repo shape
- Define rename/signature-change search coverage when relevant

**IMPORTANT: Present the plan to the user and wait for approval before proceeding.**

### Phase 3: Implement

After user approval, spawn the **coder** agent with the approved plan:

- Execute the plan step-by-step
- Before every edit, re-read the file; after every edit, read it again to confirm the applied change
- After 10+ messages or any long pause, re-read files before editing
- Run `dev-verify --quick` every 3-5 file changes, or the plan's targeted fallback if needed
- Stay within scope for straightforward work, but do not preserve reviewer-visible structural issues on refactor or AI-config style tasks
- Report blockers immediately

### Phase 4: Review

Spawn the **reviewer** agent to review the coder's changes:

- Check implementation against the approved plan
- Assess correctness, security, performance, quality, and mechanical-safety compliance
- Verify test coverage
- Produce a Must Fix / Should Fix / Nits / Verdict report

If the reviewer finds "Must Fix" items:

1. Spawn coder to address the issues
2. Spawn reviewer to re-review (max 3 cycles)

### Phase 5: Closeout

- Run full `dev-verify`, or the targeted equivalent if no unified verify entrypoint exists
- Commit with conventional message format
- Present summary to user

## Rules

- Explorer and planner are read-only — they must not modify files
- User approval gate between Plan and Implement is mandatory
- Max 3 review-fix cycles before escalating to user
- Worker must run verification every 3-5 file changes unless the plan requires a tighter cadence
- Work touching more than 5 independent files must be split into phases or parallel owners with disjoint ownership
