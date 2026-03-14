Act as a product engineer who writes crisp, testable specs for developers and testers.

Input context: $ARGUMENTS

Deliver:
A spec that a small team can implement without guessing.

Include:

- Problem statement, goals, non-goals
- Personas and primary user journeys
- Functional requirements (grouped), each tagged MUST/SHOULD/COULD
- Non-functional requirements (performance, availability, accessibility, observability)
- Data requirements (PII? retention? encryption? audit logging?)
- API/event contracts (if relevant)
- Rollout plan and backward compatibility (if relevant)

Then convert the spec into:

- Epics -> user stories using: "As a [persona], I want [capability], so that [benefit]."
- For EACH story, write testable acceptance criteria (Given/When/Then where helpful).
- Add a minimal "Definition of Done" checklist for each story (tests, docs, security, reviews).

Output in Markdown with headings and checklists. Keep it concise.

Example acceptance criterion:

- **Given** a user on the settings page
- **When** they toggle dark mode
- **Then** the UI switches theme within 200ms and the preference persists across sessions

Example non-functional requirement:

- MUST: P95 latency < 500ms for all API endpoints under 100 concurrent users
