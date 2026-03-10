Run a blind multi-reviewer audit of uncommitted changes. Multiple independent reviewers examine the same diff with zero shared context, then findings are combined and validated.

Context (optional focus area): $ARGUMENTS

## Why This Workflow

Independent reviewers catch different things. By preventing shared context, each reviewer forms their own mental model of the code and spots issues the others miss. The combination step then surfaces high-confidence findings (multiple reviewers flagged the same thing) and unique catches.

## Team Formation

Create a team using `TeamCreate` with:

- **team-lead** (you) — orchestrator, captures changes, distributes to reviewers
- **reviewer** ×3 (name them: `reviewer-alpha`, `reviewer-bravo`, `reviewer-charlie`) — independent blind reviewers
- **planner** (as `combiner`) — deduplicates and merges review findings
- **review-fix** (as `confirmer`) — validates the combined report with full context, optionally fixes issues

## Phase 0: Capture Changes

Run these yourself (team-lead) before spawning reviewers:

1. `git diff` — all unstaged changes
2. `git diff --cached` — all staged changes
3. `git diff --stat` — summary of files changed
4. Read the full content of every changed file

This is the "change package." Each reviewer gets ONLY this.

## Phase 1: Blind Review (PARALLEL — all 3 at once)

Assign to: `reviewer-alpha`, `reviewer-bravo`, `reviewer-charlie` — **launch all 3 simultaneously**

Each reviewer receives ONLY:

- The complete git diff (staged + unstaged)
- The full content of each changed file
- The optional focus area from $ARGUMENTS (if provided)

Each reviewer **MUST NOT**:

- Read any file not in the change package
- Read CLAUDE.md, project config, or any other context files
- Communicate with other reviewers
- Use Grep/Glob to explore the broader codebase

Each reviewer **MUST**:

- Review only what's provided
- Assess: correctness, bugs, logic errors, security issues, error handling gaps, edge cases, code quality, naming, structure
- Produce a report in this exact format:

```
## Blind Review: [name]

### Critical (blocks merge)
- [file:line] Description of issue

### Important (should fix before merge)
- [file:line] Description of issue

### Minor (nice to have)
- [file:line] Description of issue

### Observations
- Patterns noticed, questions raised, things that looked good
```

Gate: all 3 reviews complete.

## Phase 2: Combine

Assign to: `combiner` (planner agent)

Input: all 3 blind review reports.

Task:

1. Read all 3 reports
2. Deduplicate — same finding from multiple reviewers = higher confidence
3. Note consensus: mark each finding with who flagged it (e.g., "alpha, bravo" or "charlie only")
4. Rank by severity: Critical → Important → Minor
5. For each unique finding, keep the clearest description
6. Note any contradictions (one reviewer says it's fine, another says it's a bug)

Output:

```
## Combined Review — [N] unique findings from 3 reviewers

### Critical [count]
- [file:line] Description (flagged by: alpha, bravo, charlie) [consensus: N/3]
...

### Important [count]
- [file:line] Description (flagged by: alpha) [solo finding]
...

### Minor [count]
...

### Contradictions
- [description of disagreement, if any]

### Reviewer Agreement
- N/M findings had 2+ reviewer consensus
- N solo findings (unique to one reviewer)
```

Gate: combined report ready.

## Phase 3: Confirm & Fix

Assign to: `confirmer` (review-fix agent)

Input: combined report from Phase 2.

Unlike the blind reviewers, the confirmer **HAS full codebase access**. Task:

1. Read each finding and verify it against actual code + full project context
2. For each finding, assign a verdict:
   - **Confirmed** — real issue, severity is correct
   - **Upgraded/Downgraded** — severity adjusted with explanation
   - **Dismissed** — false positive, explain why context invalidates the finding
3. Add any findings the blind reviewers missed due to lacking context (label as "contextual finding")
4. For Critical and Important items that are safe to auto-fix (per review-fix agent's fix policy): apply the fix
5. Produce the final report

Output:

```
## Final Validated Report

### Applied Fixes
- [file:line] What was fixed and why

### Confirmed Issues (needs human decision)
- [file:line] Description — severity — consensus

### Dismissed
- [file:line] Why this was a false positive

### Contextual Findings (missed by blind reviewers)
- [file:line] Description — only visible with full project context

### Summary
- Total findings: N from blind review + N contextual
- Auto-fixed: N
- Needs human decision: N
- Dismissed: N
- Reviewer agreement rate: N%
```

## Rules

- Blind reviewers **MUST NOT** communicate with each other or access shared context
- Blind reviewers **MUST NOT** use Grep, Glob, or Read on files outside the change package
- The value of this workflow is independent perspectives — do not shortcut by sharing context
- Combiner must preserve attribution (which reviewer found what)
- Confirmer is the final authority on severity and can override blind reviewers
- If no uncommitted changes exist, abort with a message to the user
