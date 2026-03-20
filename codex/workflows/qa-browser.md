<!-- Source of truth: claude/commands/qa.md (browser mode) -->

# Browser QA Workflow

Browser-based quality assurance for Codex agent teams.

## Phase 1: Setup

- Run `browse-ctl ensure` to start the headless browser daemon
- Verify daemon is running: `browse-ctl status`

## Phase 2: Discovery

- Spawn `researcher` agent to map the target
- Navigate to target URL
- Take snapshot of interactive elements
- Enumerate navigation, forms, and key UI components

## Phase 3: Testing

- Spawn `coder` agent to execute browser QA
- Functional testing: forms, navigation, interactions
- Visual testing: screenshots, responsive checks
- Console error monitoring
- Accessibility tree analysis

## Phase 4: Auto-Fix (unless qa-only mode)

- Coder identifies source files for each issue
- Apply fixes with minimal changes
- Re-verify each fix in the browser
- Revert fixes that don't improve the issue

## Phase 5: Report

- Spawn `reviewer` agent to verify and score
- Calculate health score (navigation 25%, forms 20%, visual 20%, interactivity 15%, console 10%, accessibility 10%)
- Produce structured report with screenshots
- Report: DONE / DONE_WITH_CONCERNS / BLOCKED
