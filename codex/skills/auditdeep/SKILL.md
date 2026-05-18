---
name: auditdeep
description: Comprehensive security audit using OWASP Top 10 and ASVS as verification frameworks. Use when the user needs a thorough security assessment, penetration test plan, or compliance-oriented audit for systems they own. Triggers on "deep audit", "security audit", "OWASP audit", "comprehensive security review", "ASVS verification".
---

# Comprehensive Audit

Act as a security lead + staff engineer performing a comprehensive audit.

Explore the repo structure, key files, and CI/CD configuration before proceeding.

**Important:** Only propose activities appropriate for systems the user owns or is explicitly authorized to test. Focus on defensive verification and risk reduction.

## Task

Produce a deep audit plan + report structure using:

- OWASP Top 10 as a risk lens
- ASVS as a requirements/verification checklist (pick a level based on risk)
- A phased plan: Planning -> Execution -> Post-Execution
- Evidence-driven reporting (what to collect, how to reproduce, how to retest)

## Output Format

1. **Scope & assumptions** + what you need to proceed
2. **Target assurance level** (baseline/standard/high) + rationale
3. **Threat surface map** (components, trust boundaries, sensitive data)
4. **Verification plan:**
   - Secure design review & threat modeling
   - Code review focus areas
   - Automated checks (SAST/dependency/secret/IaC where relevant)
   - Dynamic test strategy (auth, access control, input validation, session mgmt, logging)
5. **Findings template** (Severity, Evidence, Impact, Fix, Owner, Retest)
6. **Go/No-go release criteria** ("green bar") + proof artifacts
