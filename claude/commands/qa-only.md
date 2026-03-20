Browser-based QA report without code changes — inspection only.

$ARGUMENTS

## Setup

1. Run `browse-ctl ensure` to start the daemon
2. Navigate to the target URL from $ARGUMENTS

## Phase 1: Target Discovery

1. `browse exec goto --url "{URL}"`
2. `browse exec snapshot --interactive true` — map all interactive elements
3. `browse exec links` — enumerate navigation structure
4. `browse exec forms` — identify all form fields

## Phase 2: Functional Testing

For each interactive element found:
1. Test navigation links — do they resolve?
2. Test form submissions — fill with valid data, submit, check response
3. Test error states — submit empty/invalid data, check error messages
4. Check `browse exec console` after each interaction — note any errors

## Phase 3: Visual Verification

1. `browse exec screenshot --fullPage true` — capture full page
2. Test responsive breakpoints:
   - Desktop (1440px)
   - Tablet (768px)
   - Mobile (375px)
3. Check for layout issues, overflow, broken images

## Phase 4: Accessibility Check

1. `browse exec accessibility` — full accessibility tree
2. Check for missing labels, roles, ARIA attributes
3. Verify keyboard navigation works (Tab, Enter, Escape)

## Phase 5: Health Score

Calculate weighted score (0-100):

| Category       | Weight | Criteria                          |
|---------------|--------|-----------------------------------|
| Navigation    | 25%    | Links resolve, routing works      |
| Forms         | 20%    | Submit works, validation present  |
| Visual        | 20%    | No layout breaks, responsive      |
| Interactivity | 15%    | Buttons work, states update       |
| Console       | 10%    | No errors, no warnings            |
| Accessibility | 10%    | Labels present, keyboard works    |

## Phase 6: Report

```
## Browser QA Report (Read-Only)

**URL**: {url}
**Health Score**: {N}/100
**Date**: {date}

### Issues by Severity

#### Critical
- {issue with element ref and description}

#### Important
- {issue}

#### Minor
- {issue}

### Screenshots
- {paths to saved screenshots}

### Recommendations
- {prioritized list of fixes with file:line when identifiable}
```

## Rules

- Do NOT modify any source files — report only
- Include screenshots of issues
- Be specific about element refs and selectors
- Note console errors verbatim
