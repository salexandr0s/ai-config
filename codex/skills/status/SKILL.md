---
name: status
description: Quick project health check covering git state, dependencies, quality, tests, and build. Use when the user wants to know the current state of a project or check if everything is working. Triggers on "project status", "health check", "how's the project", "is everything working", "status check".
---

# Project Status

Give a quick health check of the current project.

## Steps

1. Detect project type from config files
2. Report:
   - **Git**: branch, uncommitted changes, commits ahead/behind remote
   - **Dependencies**: check for outdated packages (`npm outdated` or equivalent)
   - **Quality**: run lint + type-check, report error/warning counts
   - **Tests**: run test suite, report pass/fail counts
   - **Build**: check if `npm run build` succeeds (dry-run if possible)
3. Summarize with a health score: **Healthy**, **Needs attention**, or **Broken**
4. List any action items in priority order
