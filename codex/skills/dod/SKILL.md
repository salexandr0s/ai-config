---
name: dod
description: Create or refine a Definition of Done for a project with tiered checklists (MVP/Standard/High-assurance). Use when the user wants to define quality standards, acceptance criteria for work completion, or a DoD checklist. Triggers on "definition of done", "DoD", "what does done look like", "quality checklist", "done criteria".
---

# Definition of Done

Create (or refine) a Definition of Done for this project.

If working in a project, read the existing configuration (package.json, CI config, test setup, linting config) to tailor the DoD to what's actually in use.

## Output

- A concise DoD checklist (global, applies to all work)
- Plus 3 DoD tiers: **MVP** / **Standard** / **High-assurance** (so the user can choose per feature)

## Ensure the DoD Covers

- Code quality (lint/format, readability)
- Tests (unit/integration/e2e expectations; flaky test handling)
- Security (dependency + secret scanning; authn/authz checks as applicable)
- Observability (logging, metrics, tracing where relevant)
- Documentation (README/runbook impact)
- Release readiness (migration/rollback plan where needed)

## Also Include

- What can be waived (if anything) and who can approve the waiver.
