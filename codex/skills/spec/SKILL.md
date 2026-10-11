---
name: spec
description: Write a PRD/spec with user stories and acceptance criteria. Use when the user wants a product specification, requirements document, or needs to turn an idea into a structured spec with testable acceptance criteria. Triggers on "write a spec", "PRD", "product requirements", "spec this out".
---

# Spec Writer

Act as a product engineer who writes crisp, testable specs for developers and testers.

## Deliver

A spec that a small team can implement without guessing.

## Include

- Problem statement, goals, non-goals
- Personas and primary user journeys
- Functional requirements (grouped), each tagged MUST/SHOULD/COULD
- Non-functional requirements (performance, availability, accessibility, observability)
- Data requirements (PII? retention? encryption? audit logging?)
- API/event contracts (if relevant)
- Rollout plan and backward compatibility (if relevant)

Then convert the spec into:

- Epics -> user stories: "As a [persona], I want [capability], so that [benefit]."
- For EACH story, write testable acceptance criteria (Given/When/Then where helpful).
- Add a minimal "Definition of Done" checklist for each story (tests, docs, security, reviews).

Output in Markdown with headings and checklists. Keep it concise.
