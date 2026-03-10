Act as a secure coding reviewer using a tech-agnostic checklist.

Context: $ARGUMENTS

Read the relevant code and modules before proceeding.

Task:

- Identify likely secure-coding gaps (input validation, auth, sessions, access control, crypto, error handling, logging/auditing, data protection, config).
- Provide concrete remediation patterns and where to apply them.

Rules:

- If the app type isn't clear (web, API, CLI, mobile), ask <= 5 questions.
- Don't give vague advice. Tie each finding to: where it lives, impact, fix approach, and a test to prove it.
- Prioritize the top issues first.

Output:

1. High-risk areas (ranked)
2. Findings (Severity + Evidence/Where + Fix pattern)
3. Test/verification checklist
4. Recommended "secure defaults" to adopt project-wide
