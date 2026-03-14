Systematic QA with health scoring. Run tests, check quality, produce a scored report.

$ARGUMENTS

## Modes

- **full** (default): entire project
- **diff**: only files changed since base branch (`git diff --name-only origin/main...HEAD`)
- **targeted**: specific scope from $ARGUMENTS (file, directory, or module)

Detect mode from arguments. If a path or "diff" is specified, use that mode.

## Phase 1: Scope Detection

1. Identify changed files (for diff/targeted modes)
2. Map consumers: who imports/calls the changed code?
3. Determine blast radius: what could break?

## Phase 2: Test Execution

1. Run the project test suite (auto-detect: vitest, jest, pytest, cargo test)
2. For untested areas, manually verify:
   - Error handling paths (pass invalid input, check error messages)
   - Boundary values (empty arrays, null, max values)
   - Concurrent operation safety (if applicable)

## Phase 3: Health Score

Calculate a weighted score (0-100):

| Category       | Weight | Criteria                                  |
| -------------- | ------ | ----------------------------------------- |
| Test pass rate | 30%    | Percentage of tests passing               |
| Coverage       | 20%    | Estimated coverage of changed code        |
| Error handling | 15%    | Boundaries validated, errors caught       |
| Type safety    | 15%    | Strict mode, no `any`, Zod at boundaries  |
| Code quality   | 10%    | No dead code, reasonable complexity       |
| Documentation  | 10%    | Public APIs documented, CHANGELOG updated |

## Phase 4: Report

Output:

```
## QA Report

**Mode**: [full/diff/targeted]
**Scope**: [description]
**Health Score**: [N]/100

### Issues by Severity

#### Critical
- [issue with file:line]

#### Important
- [issue with file:line]

#### Minor
- [issue with file:line]

### Untested Risk Zones
- [areas without coverage that could break]

### Recommendations
- [specific, actionable items]
```

## Rules

- Read-only: do not modify any files
- Run actual tests — do not estimate results
- Calculate the score honestly — do not inflate
- Be specific about gaps — vague "needs more tests" is not helpful
