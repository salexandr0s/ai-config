Create (or refine) a Definition of Done for this project.

Context: $ARGUMENTS

If working in a project, read the existing configuration (package.json, CI config, test setup, linting config) to tailor the DoD to what's actually in use.

Output:

- A concise DoD checklist (global, applies to all work)
- Plus 3 DoD tiers: MVP / Standard / High-assurance (so I can choose per feature)

Ensure the DoD covers:

- Code quality (lint/format, readability)
- Tests (unit/integration/e2e expectations; flaky test handling)
- Security (dependency + secret scanning; authn/authz checks as applicable)
- Observability (logging, metrics, tracing where relevant)
- Documentation (README/runbook impact)
- Release readiness (migration/rollback plan where needed)

Also include:

- What can be waived (if anything) and who can approve the waiver.
