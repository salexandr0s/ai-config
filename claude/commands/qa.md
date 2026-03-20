Systematic QA with health scoring. Run tests, check quality, produce a scored report.

$ARGUMENTS

## Mode Detection

Detect from $ARGUMENTS:
- **browser** (or a URL, or `--browser`): Browser-based QA — see Browser QA Mode below
- **test** (default): Test-runner QA — existing behavior below
- **both** (or `--both`): Both test-runner AND browser QA
- **qa-only**: Browser QA report without code changes (see /qa-only)

---

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

---

## Browser QA Mode

When browser mode is detected, run these phases instead of (or in addition to) the test-runner phases above.

### Phase B1: Target Discovery

1. `browse-ctl ensure` — start daemon if needed
2. `browse exec goto --url "{URL}"` — navigate to target
3. `browse exec snapshot --interactive true` — map interactive elements
4. `browse exec links` — enumerate navigation
5. `browse exec forms` — identify form fields

### Phase B2: Functional Testing

For each interactive element:
1. Test navigation links — do they resolve?
2. Test form submissions — valid data, then invalid data
3. Check error states and messages
4. `browse exec console` after each interaction — note errors

### Phase B3: Visual Verification

1. `browse exec screenshot --fullPage true` — capture full page
2. Test responsive breakpoints: Desktop (1440px), Tablet (768px), Mobile (375px)
3. Check for layout breaks, overflow, broken images

### Phase B4: Auto-Fix Loop

For each issue found:
1. Identify the source file and line
2. Apply minimal fix
3. Reload and re-verify in browser
4. Keep fix if improved, revert if not

### Phase B5: Browser Health Score

| Category       | Weight | Criteria                          |
|---------------|--------|-----------------------------------|
| Navigation    | 25%    | Links resolve, routing works      |
| Forms         | 20%    | Submit works, validation present  |
| Visual        | 20%    | No layout breaks, responsive      |
| Interactivity | 15%    | Buttons work, states update       |
| Console       | 10%    | No errors, no warnings            |
| Accessibility | 10%    | Labels present, keyboard works    |

### Phase B6: Report

Same report format as test-runner QA, with additional browser-specific sections:
- Screenshots of issues
- Console error log
- Browser health score
- Element refs for each finding
