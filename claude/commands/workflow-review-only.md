Run a thorough code review of a specific area without making any changes.

Context: $ARGUMENTS

## Team Formation

Create a team using `TeamCreate` with:

- **team-lead** (you) — orchestrator
- **researcher** — codebase exploration
- **reviewer** — quality review

## Phases

### Phase 1: Explore

Assign to: `researcher`

Task: Explore the code area specified by the context:

- Map the architecture and key patterns
- Identify dependencies and consumers
- Note anything unusual, fragile, or concerning
- List relevant test coverage

Handover to team-lead: structured exploration report.

Gate: team-lead confirms exploration covers the requested scope.

### Phase 2: Review

Assign to: `reviewer`

Input: researcher's exploration report + original context.

Task: Produce a comprehensive review covering:

- Correctness and logic issues
- Security vulnerabilities (injection, auth, data exposure)
- Performance concerns (N+1 queries, unnecessary re-renders, missing caching)
- Code quality and maintainability
- Test coverage gaps
- Deviation from project conventions (check CLAUDE.md)

Output using standard review format:

- Must Fix / Should Fix / Nits / Verdict

Handover to team-lead: complete review report.

### Phase 3: Report

Present the full review report to the user with:

- Summary: total findings by severity
- Each finding with specific file:line references
- Recommended priority order for addressing findings
- Estimated effort per finding (trivial / small / medium / large)

## Rules

- This is a **READ-ONLY** workflow — no files may be modified
- All agents have `permissionMode: plan` by design — this is intentional
- Focus on actionable findings, not style preferences
- Cite specific code with file:line, not vague concerns
- If the scope is unclear from context, ask the user before starting
