---
name: test
description: Detect the project type and run the appropriate test suite (Vitest, Jest, Playwright, pytest, cargo test). Use when the user wants to run tests, check test results, or verify a specific test file. Triggers on "run tests", "run the test suite", "check tests", "test this".
---

# Test Runner

Detect the project type and run the appropriate test suite.

## Steps

1. Check for test configuration:
   - `vitest.config.*` or `vite.config.*` with test -> run `npx vitest run`
   - `jest.config.*` or `jest` in package.json -> run `npx jest`
   - `playwright.config.*` -> run `npx playwright test`
   - `pytest.ini` or `pyproject.toml` with pytest -> run `python -m pytest`
   - `Cargo.toml` -> run `cargo test`
2. If a specific test file or pattern is mentioned, run only those tests
3. If nothing specific, run the full suite
4. Report results clearly: passed, failed, and skipped counts
5. For any failures, show the relevant error and suggest a fix
