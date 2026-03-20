Engineering architecture review — systematic technical analysis of a plan.

$ARGUMENTS

Read the current plan from context, task list, or ask the user for it.

---

## 1. Architecture Lock Analysis

- Are the interfaces and contracts stable enough to build on?
- What architectural decisions are being locked in by this plan?
- Which decisions are easily reversible vs hard to change later?
- Are there any premature abstractions or unnecessary flexibility?

## 2. Data Flow Mapping

- Trace the data flow end-to-end for each major operation
- Identify missing flows (error paths, edge cases, cleanup)
- Check: does data cross trust boundaries? Where is validation needed?
- Are there circular dependencies or hidden coupling?

## 3. Edge Case Enumeration

Systematically enumerate (not ad-hoc):
- Empty/null/undefined inputs at each boundary
- Concurrent operations (race conditions, deadlocks)
- Partial failures (network, disk, external APIs)
- Scale boundaries (what happens at 10x, 100x current load?)
- State corruption (what if process crashes mid-operation?)
- Clock/time dependencies (timezones, DST, leap seconds)

## 4. Test Plan Generation

Generate a test matrix:

| Layer       | What to Test                    | Priority |
|-------------|--------------------------------|----------|
| Unit        | {specific functions/modules}    | P0-P2    |
| Integration | {service interactions}          | P0-P2    |
| E2E         | {user-facing workflows}         | P0-P1    |

For each P0 test: describe the test case in one sentence.

## 5. Dependency Risk Assessment

- External dependencies: version pinning, breaking change risk, bus factor
- Internal dependencies: coupling analysis, change propagation
- Build/deploy dependencies: CI time impact, deployment order

## 6. Performance & Scalability

- Identify hot paths and potential bottlenecks
- Memory allocation patterns (leaks, GC pressure)
- I/O patterns (N+1 queries, unbounded reads, missing pagination)
- Caching strategy: what to cache, invalidation approach

## Output

```
## Engineering Review

### Architecture Readiness: {READY / NEEDS WORK / NOT READY}

### Locked Decisions
- {decision}: {reversibility assessment}

### Missing Flows
- {flow description}

### Critical Edge Cases
- {edge case}: {mitigation}

### Generated Test Plan
{test matrix from section 4}

### Dependency Risks
- {risk}: {severity} — {mitigation}

### Performance Concerns
- {concern}: {recommendation}

### Verdict
{APPROVE / REQUEST CHANGES / NEEDS DISCUSSION}
{Specific items to address before implementation}
```
