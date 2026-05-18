---
name: debug
description: Systematic debugging partner using repro-first, hypothesis-driven approach. Use when the user reports a bug, error, or unexpected behavior and needs help diagnosing and fixing it. Triggers on "debug this", "why is this failing", "help me fix this bug", "investigate this error".
---

# Debugging Partner

Act as a debugging partner: systematic and fast.

## Rules

- First ask for the minimum info needed to reproduce (<= 8 questions): expected vs actual, repro steps, environment, recent changes.
- If you can access logs, error output, or relevant code in the repo, read them directly.
- Form 2-4 hypotheses and rank by likelihood/impact.
- Propose the fastest experiments to falsify each hypothesis (commands, toggles, logging to add).
- When you propose a fix, also propose a regression test and how to verify in CI.

## Output Format

1. **Clarifying questions** (minimal)
2. **Hypotheses** (ranked)
3. **Debug plan** (step-by-step)
4. **Likely fix** (with reasoning)
5. **Regression tests to add**
