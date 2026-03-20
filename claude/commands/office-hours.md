Pre-code product diagnostic. Stress-test ideas before writing code.

$ARGUMENTS

---

## Mode Detection

Detect from $ARGUMENTS:
- **startup** (or "idea", "validate", "product"): Startup-style forcing questions
- **builder** (or "design", "brainstorm", "think"): Design thinking brainstorm
- If unclear, ask: "Are you validating a new idea (startup mode) or brainstorming a design (builder mode)?"

---

## Startup Mode

Ask these 6 forcing questions **ONE AT A TIME**. Wait for the answer before asking the next.

1. **Demand Reality:** "Who is doing this manually today, and what exactly do they do?"
2. **Status Quo:** "What is the current workaround? Be specific — what tools, what steps, what breaks?"
3. **Desperate Specificity:** "Name one real person (or type of person) who would pay for this. What's their day like?"
4. **Narrowest Wedge:** "What's the smallest version of this that someone would actually use and get value from?"
5. **Observation:** "What surprised you watching someone use the current solution (or attempt to solve this problem)?"
6. **Future-Fit:** "Why does this become MORE essential in 3 years, not less?"

After all 6 answers:

1. Summarize key insights from the answers
2. Identify the strongest and weakest signals
3. Propose 2–3 approaches ranked by:
   - **Impact** (who benefits, how much)
   - **Feasibility** (what's needed to build it)
   - **Effort compression** — estimate for each approach:

| Approach | Human Time | AI-Assisted Time | Compression |
|----------|-----------|-------------------|-------------|
| A        | X days    | Y hours           | X/Y ratio   |

4. **Completeness scoring:** When the marginal AI cost of a more complete approach is near-zero, recommend the complete approach
5. Generate a design doc and save to `docs/DESIGN.md` (or `DESIGN.md` in project root if no `docs/` directory)

---

## Builder Mode

Design thinking brainstorm — 5 phases:

### Empathize
- Who are the users? What are their pain points?
- What context are they in when they'd use this?

### Define
- Restate the problem as a clear problem statement
- What constraints exist? (technical, time, resource)

### Ideate
- Generate 5+ possible solutions (breadth over depth)
- Include at least one "wild card" unconventional approach
- Rank by effort vs impact

### Prototype
- For the top 2 approaches: describe the minimum testable version
- What would you build in 1 day to test the hypothesis?
- What data would prove/disprove the approach?

### Test
- How would you validate each prototype?
- What does success look like? What metrics?
- What's the kill criterion — when do you stop and pivot?

After all phases:
1. Produce effort compression table (same format as startup mode)
2. Generate design doc and save to `docs/DESIGN.md` (or `DESIGN.md` in project root)

---

## Design Doc Format

```markdown
# Design: {Project/Feature Name}

## Problem
{1-2 sentence problem statement}

## Key Insights
{Bullet points from the diagnostic session}

## Recommended Approach
{Description of the chosen approach and why}

## Effort Estimate
{Effort compression table}

## Open Questions
{Unresolved items that need answers before building}

## Next Steps
{Concrete actions to take}
```
