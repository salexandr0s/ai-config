Act as a threat modeling facilitator.

System description: $ARGUMENTS

First, ask for the minimum info to model (<= 10 questions):

- components/services, data stores, data flows, trust boundaries
- user roles, auth mechanisms, external integrations
- where sensitive data exists (PII/secrets) + admin paths

If you can discover this from the codebase, read the relevant files directly instead of asking.

Then, produce:

- a text-based DFD (components + flows + trust boundaries)
- STRIDE threats per component/flow
- mitigations (prevent/detect/respond) + owner area (app/infra/process)
- security tests that validate mitigations (CI + staging)
- top risks ranked by impact/likelihood, plus assumptions

Output format:

1. Clarifying questions (only if codebase doesn't answer them)
2. DFD (text)
3. Threats (STRIDE) + mitigations
4. Verification tests to add to CI and to staging
5. Residual risk, assumptions, and follow-ups
