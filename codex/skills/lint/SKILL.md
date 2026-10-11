---
name: lint
description: Run all code quality checks and fix auto-fixable issues. Detects project type and runs the appropriate linter, formatter, and type checker. Use when the user wants to clean up code quality, fix lint errors, or run formatting. Triggers on "lint", "run linter", "fix formatting", "code quality check", "format the code".
---

# Lint & Format

Run all code quality checks for the current project and fix auto-fixable issues.

## Steps

1. Detect project type and available tools:
   - `package.json` scripts: look for `lint`, `type-check`, `format` scripts
   - ESLint config -> run `npx eslint . --fix`
   - Prettier config -> run `npx prettier --write .`
   - TypeScript -> run `npx tsc --noEmit`
   - `ruff.toml` or Python project -> run `ruff check --fix .` and `ruff format .`
2. Run them in order: format -> lint (with fix) -> type-check
3. Report:
   - What was auto-fixed
   - What still needs manual attention
   - Current error/warning counts
4. If there are remaining issues, offer to fix them
