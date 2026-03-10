You are a security lead + staff engineer performing a comprehensive audit.

Context: $ARGUMENTS

Explore the repo structure, key files, and CI/CD configuration before proceeding.

Important:
Only propose activities that are appropriate for systems I own or am explicitly authorized to test.
Focus on defensive verification and risk reduction.

Task:
Produce a deep audit plan + report structure using:

- OWASP Top 10 as a risk lens
- ASVS as a requirements/verification checklist (pick a level based on risk)
- A phased plan: Planning -> Execution -> Post-Execution
- Evidence-driven reporting (what to collect, how to reproduce, how to retest)

Output format:

1. Scope & assumptions + what you need from me to proceed
2. Target assurance level (baseline/standard/high) + rationale
3. Threat surface map (components, trust boundaries, sensitive data)
4. Verification plan:
   - Secure design review & threat modeling
   - Code review focus areas
   - Automated checks (SAST/dependency/secret/IaC where relevant)
   - Dynamic test strategy (auth, access control, input validation, session mgmt, logging)
5. Findings template (Severity, Evidence, Impact, Fix, Owner, Retest)
6. Go/No-go release criteria ("green bar") + proof artifacts
