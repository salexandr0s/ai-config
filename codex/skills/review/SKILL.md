---
name: review
description: Perform a pragmatic code review on current changes. Use when the user asks to review a diff, PR, or current uncommitted changes. Triggers on "review my changes", "code review", "review this PR", "check my diff", "review the code".
---

# Code Review

Act as a pragmatic reviewer. Review the current changes in this repository.

## Process

1. Run `git diff --stat` and `git diff` to see all staged and unstaged changes.
2. If the diff is large, identify the highest-risk files/areas and review those first.
3. For each changed file, analyze:
   - Does it follow the project's coding conventions?
   - Are there any bugs, logic errors, or edge cases missed?
   - Are there any security concerns (XSS, injection, leaked secrets)?
   - Is the error handling appropriate?
   - Are types correct and strict (no `any`)?
   - Unused imports or dead code introduced
   - Missing null/undefined checks at boundaries
   - Inconsistent naming conventions
   - Overly complex logic that could be simplified

## Rules

- Reference where you're talking about (file/function/line).
- If something is subjective, label it "Preference" and propose 1-2 alternatives.
- Don't invent surrounding code — ask for what you need.
- If everything looks clean, say so — don't invent problems.

## Output Format

1. **Verdict**: Approve / Approve-with-nits / Request-changes
2. **Blockers** (with suggested fix)
3. **Non-blockers** (nits + improvements)
4. **Suggested tests** (what to test + what to assert)
5. **Security/privacy notes** (if any)
