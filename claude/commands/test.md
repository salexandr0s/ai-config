Detect the project type and run the appropriate test suite.

1. Check for test configuration:
   - `vitest.config.*` or `vite.config.*` with test → run `npx vitest run`
   - `jest.config.*` or `jest` in package.json → run `npx jest`
   - `playwright.config.*` → run `npx playwright test`
   - `pytest.ini` or `pyproject.toml` with pytest → run `python -m pytest`
   - `Cargo.toml` → run `cargo test`
2. If a specific test file or pattern is provided as $ARGUMENTS, run only those tests
3. If no arguments, run the full suite
4. Report results clearly: passed, failed, and skipped counts
5. For any failures, show the relevant error and suggest a fix
6. If tests fail due to environment issues (missing deps, stale locks, port conflicts), diagnose and fix before re-running
7. For projects with multiple test types (unit + integration + E2E), run unit tests first; only run E2E if unit tests pass

Prefer `dev-verify` when the user wants a full quality check. Use `/test` when specifically running only tests.
