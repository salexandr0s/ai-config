# Feature Development Workflow

Use this prompt template when building a new feature with Codex multi-agent orchestration.

## Usage

```
codex "Follow the workflow in workflows/feature.md to implement: <feature description>"
```

## Workflow

You are orchestrating a feature development workflow using your available agents. Follow these phases in order:

### Phase 1: Explore

Spawn the **researcher** agent to investigate the codebase:

- Map the architecture and files relevant to this feature
- Identify patterns, conventions, and dependencies
- Find existing code that can be reused
- Flag risks and unknowns

Wait for researcher to complete before proceeding.

### Phase 2: Plan

Spawn the **planner** agent with the researcher's findings:

- Design an implementation plan with numbered steps
- Identify all files to create or modify
- Define testing strategy and edge cases
- Assess risks and mitigations

**IMPORTANT: Present the plan to the user and wait for approval before proceeding.**

### Phase 3: Implement

After user approval, spawn the **coder** agent with the approved plan:

- Execute the plan step-by-step
- Run `dev-verify --quick` every 3-5 file changes
- Stay within plan scope
- Report blockers immediately

### Phase 4: Review

Spawn the **reviewer** agent to review the coder's changes:

- Check implementation against the approved plan
- Assess correctness, security, performance, quality
- Verify test coverage
- Produce a Must Fix / Should Fix / Nits / Verdict report

If the reviewer finds "Must Fix" items:

1. Spawn coder to address the issues
2. Spawn reviewer to re-review (max 3 cycles)

### Phase 5: Closeout

- Run full `dev-verify`
- Commit with conventional message format
- Present summary to user

## Rules

- Explorer and planner are read-only — they must not modify files
- User approval gate between Plan and Implement is mandatory
- Max 3 review-fix cycles before escalating to user
- Worker must run verification every 3-5 file changes
