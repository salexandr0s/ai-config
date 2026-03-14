Run an engineering retrospective based on git history and project state.

$ARGUMENTS

## Time Window

Parse from arguments:

- `1w` → 1 week
- `2w` → 2 weeks (default if no time pattern)
- `30d` → 30 days
- `3m` → 3 months

Convert to `git log --since` format.

## Phase 1: Data Gathering

### Commit Analysis

- Count by type (feat/fix/chore/refactor/test/docs)
- Churn hotspots: files changed most often (`git log --since=<window> --name-only --pretty=format: | sort | uniq -c | sort -rn | head -15`)
- Total lines added/removed: `git diff --stat --shortstat $(git log --since=<window> --format=%H | tail -1)..HEAD`

### Quality Signals

- Fix ratio: fixes / total commits (high ratio = reactive mode)
- Reverts: `git log --since=<window> --grep="revert" --oneline`
- WIP commits: `git log --since=<window> --grep="wip\|WIP" --oneline`
- TODO delta: net change in TODO/FIXME count

### Process Signals

- Average commit size (files per commit)
- Long-lived branches: branches not merged in >1 week
- Contributor activity: `git shortlog -sn --since=<window>`

### Context

- Check ~/GitHub/.memory/journal/ for session notes in the time window
- Check project memory for relevant context

## Phase 2: Analysis

From the data, identify:

- What went well (velocity, quality improvements, good patterns)
- What didn't go well (high churn, reactive fixes, scope creep)
- Surprises (unexpected patterns in the data)
- 2-4 themes that emerge

## Phase 3: Report

```
## Engineering Retrospective: [project] ([time window])

### Summary
[2-3 sentence narrative of the period]

### By the Numbers

| Metric | Value |
|--------|-------|
| Total commits | N |
| By type | feat: N, fix: N, chore: N, ... |
| Lines added/removed | +N / -N |
| Fix ratio | N% |
| Top churn file | path (N changes) |
| Contributors | N |

### Themes

#### [Theme 1]
Evidence: [cite specific commits or patterns]
Impact: [what this means for the project]

#### [Theme 2]
...

### Action Items
- [ ] [Specific, time-bound action] — owner: [suggest who]
- [ ] ...
```

## Rules

- Base analysis on git data, not impressions
- Cite specific commits as evidence (hash + message)
- Keep it blameless — focus on patterns, not people
- Action items must be specific and time-bound
