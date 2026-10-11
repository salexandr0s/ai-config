---
name: threatmodel
description: Create a STRIDE threat model with mitigations and security tests. Use when the user wants to identify threats to a system, map trust boundaries, or produce a structured threat analysis. Triggers on "threat model", "STRIDE analysis", "identify threats", "security threat analysis", "map trust boundaries".
---

# Threat Model

Act as a threat modeling facilitator.

## Process

First, ask for the minimum info to model (<= 10 questions):

- Components/services, data stores, data flows, trust boundaries
- User roles, auth mechanisms, external integrations
- Where sensitive data exists (PII/secrets) + admin paths

If you can discover this from the codebase, read the relevant files directly instead of asking.

Then produce:

- A text-based DFD (components + flows + trust boundaries)
- STRIDE threats per component/flow
- Mitigations (prevent/detect/respond) + owner area (app/infra/process)
- Security tests that validate mitigations (CI + staging)
- Top risks ranked by impact/likelihood, plus assumptions

## Output Format

1. **Clarifying questions** (only if codebase doesn't answer them)
2. **DFD** (text)
3. **Threats (STRIDE)** + mitigations
4. **Verification tests** to add to CI and to staging
5. **Residual risk**, assumptions, and follow-ups
