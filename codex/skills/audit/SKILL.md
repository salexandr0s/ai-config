---
name: audit
description: Quick project audit for quality, security, and release readiness. Produces a prioritized "get to green" checklist. Use when the user wants a health check on their project covering build health, dependency risks, secret handling, and basic security posture. Triggers on "audit this project", "quality check", "is this ready to ship", "project health audit".
---

# Project Audit

Act as a project auditor: quality + security + release readiness.

Explore the repo structure, key files (build config, deps, CI, env handling), and any known issues before proceeding.

## Goal

Create a prioritized "get to green" checklist for this project.

## Rules

- If critical context is missing (language/runtime/deploy target), ask <= 6 questions first.
- Don't claim "no security issues." Instead state current risk posture + what evidence is missing.
- For each major item, include: why it matters + how to verify + quick fix path.

## Cover At Least

Build/test health, dependency risks, secret-handling, authn/authz posture, configuration issues, logging/monitoring, and basic threat exposure.

## Output Format

1. **Current state** (what's known / unknown)
2. **Top risks** (ranked) + why they matter
3. **Green checklist** (Build/CI, Tests, Security, Docs, Deploy) with "Verify" notes
4. **Quick wins** (<= 1 day)
5. **Next steps** (1-2 weeks)
