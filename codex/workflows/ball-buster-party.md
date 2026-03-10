# Ball-Buster Party Workflow

Spawn multiple ball-buster agents in parallel — one per feature/module — to tear apart the entire codebase, then combine into a unified roast report.

## Usage

```
codex "Follow the workflow in workflows/ball-buster-party.md to roast: <project or scope>"
```

## Workflow

You are orchestrating a parallel codebase critique. Multiple ball-buster agents each focus on one feature or module, then findings are combined into a devastating unified report.

### Phase 0: Scout

Spawn the **explorer** agent to map the codebase into distinct features or modules:

- Read project config, entry points, directory structure
- Identify 3-7 logical boundaries (features, modules, layers)
- For each: name, description, key files, approximate scope

Review the list. Merge anything too small, split anything too large. If a scope was specified, filter accordingly.

### Phase 1: Ball-Buster Party (PARALLEL)

Spawn **one ball-buster agent per feature/module** — all simultaneously.

Each ball-buster receives:

- Their assigned feature/module and its file boundaries
- Permission to read project-wide config for context
- The instruction: "Tear this apart. Question every decision. Miss nothing."

Each ball-buster produces a report covering:

- The worst offenders (ranked, with file:line and better alternatives)
- Detailed findings on architecture, quality, naming, deps, performance, security, tests
- What's actually good (honest acknowledgment)
- A score out of 10

Ball-busters must NOT review files outside their scope or communicate with each other.

Wait for all reports to complete.

### Phase 2: Combine

Spawn the **planner** agent with all ball-buster reports:

- Identify codebase-wide patterns (same bad decision across features)
- Rank all findings by severity
- Rank features worst-to-best with scores
- List top 10 worst offenders across the whole codebase
- Note cross-feature inconsistencies
- Produce the unified Ball-Buster Party Report

### Phase 3: Deliver

Present the combined report to the user with:

- Full unified report
- Feature rankings and overall score
- Suggested fix priority order

## Rules

- This is a **READ-ONLY** workflow — no files may be modified
- Ball-busters work independently — no shared context between them
- Every critique must include file:line and a better alternative
- Aim for 3-7 parallel ball-busters
- Acknowledge good work — credibility requires fairness
