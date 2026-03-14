<!-- Source of truth: claude/commands/workflow-bugfix.md — keep phases and rules in sync -->

# Bugfix Workflow

Use this prompt template for streamlined bug investigation and fixing with Codex multi-agent orchestration.

## Usage

```
codex "Follow the workflow in workflows/bugfix.md to fix: <bug description>"
```

## Workflow

You are orchestrating a bugfix workflow using your available agents. Follow these phases in order:

### Phase 1: Investigate

Spawn the **researcher** agent to track down the bug:

- Reproduce or confirm the bug from code analysis
- Trace execution paths to find the root cause
- Identify all affected files (not just the symptom location)
- Check for the same pattern elsewhere
- Note existing test coverage

Wait for researcher to complete before proceeding.

### Phase 2: Fix

Spawn the **coder** agent with the researcher's investigation report:

- Write a mini-plan (3-5 lines) before implementing
- Fix the root cause, not just the symptom
- Add or update tests covering the bug scenario
- Run `dev-verify --quick` after changes

No user approval gate — trust the review phase to catch issues.

### Phase 3: Review

Spawn the **reviewer** agent to validate the fix:

- Confirm fix addresses root cause
- Check for regressions or side effects
- Verify test coverage for the bug scenario
- Produce a Must Fix / Should Fix / Nits / Verdict report

If the reviewer finds "Must Fix" items:

1. Spawn coder to address the issues
2. Spawn reviewer to re-review (max 2 cycles)

### Phase 4: Closeout

- Run full `dev-verify`
- Commit with message: `fix(scope): description`
- Present summary: root cause, fix applied, tests added

## Rules

- No user approval gate — the review phase provides quality assurance
- Explorer is read-only — must not modify files
- Max 2 review-fix cycles before escalating to user
- Worker must add tests covering the bug scenario
- Fix root cause, not symptoms
