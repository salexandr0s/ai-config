---
name: adr
description: Write an Architecture Decision Record (ADR) with options, tradeoffs, and a recommended decision. Use when the user needs to document an architectural choice, compare technical approaches, or create a formal decision record. Triggers on "ADR", "architecture decision", "document this decision", "compare approaches".
---

# Architecture Decision Record

Act as an architect writing an ADR.

## Task

Propose an ADR with 2-4 viable options, a recommended decision, and consequences.

## Rules

- If key context is missing (constraints, scale, compliance, org preferences), ask <= 6 questions first.
- Prefer the simplest option that meets requirements.
- Call out risks + mitigations, and what would make us revisit the decision.

## ADR Format

- **Title**
- **Status** (Proposed)
- **Context**
- **Decision Drivers**
- **Considered Options** (pros/cons)
- **Decision** (recommended)
- **Consequences** (positive/negative)
- **Revisit triggers**
- **Follow-ups** (spikes/tests to validate)
