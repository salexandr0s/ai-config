# Parallel Blind Review Workflow

Use this prompt template for a blind multi-reviewer audit of uncommitted changes, using Codex multi-agent orchestration.

## Usage

```
codex "Follow the workflow in workflows/blind-review.md to blind-review changes. Focus area: <optional focus>"
```

## Workflow

You are orchestrating a blind review where multiple independent reviewers examine the same diff with zero shared context. The value is independent perspectives — each reviewer forms their own mental model.

### Phase 0: Capture Changes

Before spawning reviewers, capture the change package yourself:

1. Run `git diff` (unstaged) and `git diff --cached` (staged)
2. Run `git diff --stat` for file summary
3. Read the full content of every changed file

If no uncommitted changes exist, abort and tell the user.

### Phase 1: Blind Review (PARALLEL)

Spawn **3 reviewer agents simultaneously**, each receiving ONLY:

- The complete git diff (staged + unstaged)
- Full content of each changed file
- Optional focus area (if provided)

Each reviewer must NOT access any other files, config, or project context. Each produces:

```
## Blind Review: [reviewer-N]

### Critical (blocks merge)
- [file:line] Description

### Important (should fix before merge)
- [file:line] Description

### Minor (nice to have)
- [file:line] Description

### Observations
- Patterns, questions, things that looked good
```

Wait for all 3 reviews to complete.

### Phase 2: Combine

Spawn the **planner** agent with all 3 review reports:

- Deduplicate findings — same issue from multiple reviewers = higher confidence
- Mark consensus: which reviewers flagged each finding
- Rank by severity: Critical > Important > Minor
- Note contradictions (one says fine, another says bug)

Output:

```
## Combined Review — N unique findings from 3 reviewers

### Critical [count]
- [file:line] Description (flagged by: 1, 2, 3) [consensus: N/3]

### Important [count]
- [file:line] Description (flagged by: 1) [solo finding]

### Minor [count]
...

### Contradictions
- [description of disagreements]

### Reviewer Agreement
- N/M findings had 2+ reviewer consensus
- N solo findings
```

### Phase 3: Validate

Spawn the **reviewer** agent (with full codebase access this time) to validate the combined report:

- Verify each finding against actual code + full project context
- For each finding assign: Confirmed / Upgraded / Downgraded / Dismissed
- Add contextual findings the blind reviewers missed
- Present the final validated report

## Rules

- Blind reviewers must NOT access files outside the change package
- Blind reviewers must NOT communicate with each other
- The value is independent perspectives — do not shortcut by sharing context
- Combiner must preserve attribution (which reviewer found what)
- Final reviewer is the authority on severity and can override blind reviewers
- If no uncommitted changes exist, abort with a message to the user
