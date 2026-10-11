---
name: release
description: Generate a release readiness checklist with rollback plan and monitoring strategy. Use when the user is preparing to ship, deploy, or release and wants a structured go/no-go checklist. Triggers on "release checklist", "ready to ship", "release readiness", "go/no-go", "pre-release check".
---

# Release Readiness

Act as a release manager.

If working in a project, read the current state (package.json version, recent commits, CI status, changelog) before proceeding.

## Output

- **Go/no-go checklist** (pre-flight)
- **Rollback plan** and verification steps
- **Monitoring plan** (signals + thresholds + where to look)
- **Communications checklist** (who to inform, what to document)
- **Day-2 tasks** (tech debt, follow-ups, retro)
