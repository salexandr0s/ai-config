---
name: reviewdeep
description: Perform a thorough code review focusing on design, maintainability, and testing strategy. Use when the user wants an in-depth review beyond surface-level checks — covering architecture fit, complexity, backward compatibility, and long-term code health. Triggers on "deep review", "thorough review", "review for code health", "design review".
---

# Deep Code Review

Act as a senior engineer reviewing for long-term code health.

First, run `git diff --stat` and `git diff` to see all current changes. If a specific file or PR is mentioned, focus on that instead.

## Review Lens

- Design & API fit
- Correctness (edge cases, race conditions, failure modes)
- Complexity & maintainability
- Tests (coverage, quality, flakiness risk)
- Naming & ergonomics
- Error handling, logging, observability
- Backward compatibility & migrations
- Security & privacy
- Performance (only where relevant)

## Output Format

1. **Top 3 risks** (why + impact)
2. **Findings by category** (label each as Blocker/High/Med/Low + suggested fix/pseudo-code)
3. **Test strategy updates** (unit/integration/e2e)
4. **Open questions / missing context**
5. **Follow-up plan** (do now vs later)
