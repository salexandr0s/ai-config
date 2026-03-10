Spawn a pack of ball-busters to tear apart the entire codebase — one per feature/module — then combine into a unified roast report.

Context (optional scope or focus): $ARGUMENTS

## Why This Workflow

One ball-buster is scary. A whole party of them working in parallel — each focused on a single feature or module — leaves nowhere to hide. Every component gets dedicated, thorough scrutiny, and the combined report reveals codebase-wide patterns of bad decisions.

## Team Formation

Create a team using `TeamCreate` with:

- **team-lead** (you) — orchestrator, maps the codebase into features, assigns ball-busters, combines results
- **researcher** (as `scout`) — quick codebase scan to identify features/modules to assign
- **ball-buster** ×N (name them: `buster-1`, `buster-2`, `buster-3`, etc.) — one per feature/module, spawned dynamically based on scout findings
- **planner** (as `combiner`) — merges all ball-buster reports into a unified roast

## Phase 0: Scout the Codebase

Assign to: `scout` (researcher agent)

Task: Quickly map the codebase into distinct features or modules that can be independently critiqued:

1. Read project config, entry points, directory structure
2. Identify logical boundaries — features, modules, layers, or domains
3. For each, list:
   - Name and short description
   - Key files and directories
   - Approximate scope (small / medium / large)

Output: a numbered list of features/modules with their file boundaries.

Gate: team-lead reviews the list, merges any that are too small, splits any that are too large. Aim for 3-7 assignments. If $ARGUMENTS specifies a scope, filter to only the relevant features.

## Phase 1: Ball-Buster Party (PARALLEL — all at once)

Assign to: one `ball-buster` per feature/module — **launch all simultaneously**

Each ball-buster receives:

- Their assigned feature/module name and description
- The specific files and directories to focus on
- Permission to read project-wide config (CLAUDE.md, package.json, tsconfig, etc.) for context
- The instruction: "Tear this apart. Question every decision. Miss nothing."

Each ball-buster **MUST**:

- Read every file in their assigned scope
- Critique architecture, code quality, naming, dependencies, performance, security, tests
- For every finding: explain what's wrong, why it matters, and what should have been done
- Use the ball-buster report format:

```
## Ball-Buster Report: [Feature/Module Name]

### The Worst Offenders
1. [Issue] — file:line
   Why it's bad: ...
   What you should have done: ...

### Detailed Findings
- [file:line] Critique with alternative

### What's Actually Good
- [Honest acknowledgment of good work]

### Verdict
[Would you trust this feature in production?]
Score: X/10
```

Each ball-buster **MUST NOT**:

- Review files outside their assigned scope (except shared config)
- Communicate with other ball-busters

Gate: all ball-buster reports complete.

## Phase 2: Combine

Assign to: `combiner` (planner agent)

Input: all ball-buster reports.

Task:

1. Read every report
2. Identify codebase-wide patterns — the same bad decision repeated across features
3. Rank all findings by severity across the entire codebase
4. Note which features are in the worst shape and which are actually solid
5. Calculate overall scores

Output:

```
## Ball-Buster Party Report — [Project Name]

### Codebase-Wide Patterns (the systemic problems)
1. [Pattern seen across N features]
   Where: [list of features/files]
   Why it's a problem: ...
   What should be done: ...

### Feature Rankings (worst to best)
| Feature          | Score | Worst Issue                        |
| ---------------- | ----- | ---------------------------------- |
| [name]           | X/10  | [one-line summary]                 |
...

### Top 10 Worst Offenders (across all features)
1. [file:line] — [issue] (from [feature])
2. ...

### Cross-Feature Inconsistencies
- [Feature A does X, Feature B does Y for the same thing]

### What's Actually Done Well
- [Patterns or features that are genuinely solid]

### Overall Verdict
[Honest overall assessment]
Overall Score: X/10

### Recommended Fix Priority
1. [Systemic issue — fix this first, it affects everything]
2. [Feature-specific — highest impact]
3. ...
```

## Phase 3: Deliver

Assign to: team-lead

Present the combined report to the user with:

- The full combined report from Phase 2
- Individual feature reports available on request
- A suggested order of attack for fixing the worst issues

## Rules

- Ball-busters **MUST NOT** communicate with each other — independent perspectives
- Ball-busters **MUST NOT** review files outside their assigned scope (shared config is OK)
- This is a **READ-ONLY** workflow — no files may be modified
- Every critique **MUST** include file:line references
- Every critique **MUST** suggest the better alternative
- Don't hold back — the whole point is brutal honesty
- But acknowledge good work — credibility requires fairness
- Aim for 3-7 parallel ball-busters — fewer than 3 isn't a party, more than 7 gets noisy
