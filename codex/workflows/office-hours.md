<!-- Source of truth: claude/commands/office-hours.md -->

# Office Hours Workflow

Pre-code product diagnostic for Codex agent teams.

## Phase 1: Context Gathering

- Spawn `researcher` agent to gather project context
- Read existing docs, README, DESIGN.md if present
- Identify project stage and current state

## Phase 2: Interactive Diagnostic

Mode-dependent (startup or builder):

**Startup mode:**
- Present 6 forcing questions one at a time
- Capture answers and synthesize insights
- Generate effort compression table

**Builder mode:**
- Run 5-phase design thinking process
- Generate and rank solution approaches
- Prototype specifications for top approaches

## Phase 3: Design Doc

- Generate structured design document
- Save to `docs/DESIGN.md` or project root
- Include effort estimates and open questions
- Present summary to user for review
