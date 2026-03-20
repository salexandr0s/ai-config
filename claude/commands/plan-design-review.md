Design dimension ratings — systematic quality assessment across 7 dimensions.

$ARGUMENTS

Read the current plan from context, task list, or ask the user for it.

---

## Dimensions

Rate each dimension 0–10. For each:
1. Current score with brief justification
2. What would make it a 10?
3. Concrete fix suggestions for anything below 8

### 1. Simplicity
- Is this the simplest approach that solves the problem?
- Could a junior developer understand and maintain this?
- Are there unnecessary abstractions, indirections, or configurability?

### 2. Extensibility
- Can new features be added without modifying existing code?
- Are extension points in the right places?
- Is there over-engineering for hypothetical future needs?

### 3. Testability
- Can each component be tested in isolation?
- Are dependencies injectable?
- Are there hidden side effects that make testing hard?

### 4. Performance
- Are there obvious bottlenecks in the design?
- Is the approach efficient for the expected scale?
- Are there unnecessary computations, copies, or allocations?

### 5. Security
- Are trust boundaries identified and enforced?
- Is input validated at system boundaries?
- Are secrets, tokens, and credentials handled safely?
- OWASP top 10 considerations for web-facing components

### 6. Developer Experience (DX)
- Is the API intuitive? Would a new team member understand it?
- Are error messages helpful?
- Is the debugging story good? (logging, tracing, observability)

### 7. Observability
- Can you tell what the system is doing at runtime?
- Are there appropriate logs, metrics, and health checks?
- Can you diagnose issues without redeploying?

## UI Dimensions (if applicable)

If the plan involves UI work, also read `~/.claude/uiux-contract/design_tokens.json` and rate:
- Consistency with design tokens
- Accessibility (WCAG compliance)
- Responsiveness

## Output

```
## Design Review Scorecard

| Dimension     | Score | Key Issue                      |
|---------------|-------|-------------------------------|
| Simplicity    | N/10  | {brief}                       |
| Extensibility | N/10  | {brief}                       |
| Testability   | N/10  | {brief}                       |
| Performance   | N/10  | {brief}                       |
| Security      | N/10  | {brief}                       |
| DX            | N/10  | {brief}                       |
| Observability | N/10  | {brief}                       |
| **Average**   | **N** |                               |

### Improvement Roadmap

#### Must Address (score < 6)
- {dimension}: {specific fix}

#### Should Address (score 6-7)
- {dimension}: {specific fix}

#### Nice to Have (score 8-9)
- {dimension}: {what would make it a 10}

### Verdict
{Overall assessment and top 3 recommendations}
```
