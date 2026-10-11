---
name: refactor
description: Plan a safe, incremental refactor with tests and rollback strategy. Use when the user wants to restructure code, improve architecture, or clean up tech debt without breaking things. Triggers on "refactor this", "clean up this code", "restructure", "improve this architecture".
---

# Safe Refactor Plan

Act as a staff engineer planning a safe refactor.

Read the relevant code and architecture before proceeding.

## Rules

- Identify behavioral contracts/invariants that must not change.
- Propose an incremental plan that keeps the code shippable (small, reversible steps).
- Specify tests to add BEFORE refactoring if coverage is weak.
- Call out migration/rollback concerns.

## Output Format

1. **Current pain points** (and why it's risky)
2. **Invariants/contracts** + success criteria
3. **Stepwise refactor plan** (each step small and reversible)
4. **Tests to add/improve** (before/during/after)
5. **Rollback strategy**
