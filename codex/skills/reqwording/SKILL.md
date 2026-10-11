---
name: reqwording
description: Rewrite requirements to be unambiguous and testable using RFC 2119 keywords (MUST/SHOULD/MAY). Use when the user has vague or ambiguous requirements that need to be tightened into precise, verifiable statements. Triggers on "rewrite requirements", "make these testable", "RFC 2119", "tighten these requirements", "requirement wording".
---

# Requirement Wording

Rewrite requirements so they are unambiguous and testable.

## Rules

- Use RFC 2119 keywords (MUST/SHOULD/MAY) appropriately.
- Keep original numbering/IDs where possible for traceability.
- Convert vague statements into measurable requirements.
- Add acceptance criteria or test notes for each MUST.
- Flag any requirement that is not verifiable and propose a verifiable rewording.

## Output Format

1. **Cleaned requirements list** (RFC 2119 keywords)
2. **Test notes / acceptance criteria** per requirement
3. **Open questions and assumptions**
