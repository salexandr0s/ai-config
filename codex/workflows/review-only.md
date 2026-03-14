<!-- Source of truth: claude/commands/workflow-review-only.md — keep phases and rules in sync -->

# Read-Only Code Review Workflow

Use this prompt template for thorough code review without making any changes, using Codex multi-agent orchestration.

## Usage

```
codex "Follow the workflow in workflows/review-only.md to review: <area to review>"
```

## Workflow

You are orchestrating a read-only code review using your available agents. No files are modified in this workflow.

### Phase 1: Explore

Spawn the **researcher** agent to map the code area:

- Map architecture and key patterns in the specified area
- Identify dependencies and consumers
- Note anything unusual, fragile, or concerning
- List relevant test coverage

Wait for researcher to complete before proceeding.

### Phase 2: Review

Spawn the **reviewer** agent with the researcher's findings:

- Assess correctness and logic issues
- Check for security vulnerabilities (injection, auth, data exposure)
- Identify performance concerns (N+1 queries, missing caching, unnecessary work)
- Evaluate code quality and maintainability
- Find test coverage gaps
- Check convention adherence

Use 2-pass structure:

Pass 1: CRITICAL (blocking) — correctness bugs, security vulnerabilities,
data integrity, breaking changes without migration

Pass 2: INFORMATIONAL (non-blocking) — performance, code quality,
test coverage, conventions, documentation

### Phase 3: Report

Present the complete review to the user:

- Summary: total findings by severity
- Each finding with specific file:line references
- Recommended priority order for addressing findings
- Estimated effort per finding (trivial / small / medium / large)

## Rules

- This is a **READ-ONLY** workflow — no files may be modified
- Only researcher and reviewer agents are used — no coder
- Focus on actionable findings, not style preferences
- Cite specific file:line references, not vague concerns
- If scope is unclear, ask the user before starting
