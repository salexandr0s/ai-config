Run a comprehensive workspace health check with diagnosis and recommendations.

Scope: $ARGUMENTS (blank = current project; "all" = check all active projects in ~/GitHub)

1. Run `dev-doctor` (or `dev-verify` if dev-doctor not yet installed) and capture output

2. ADDITIONAL CHECKS (beyond dev-verify):
   - Outdated dependencies: `npm outdated` / `cargo outdated` / `pip list --outdated`
   - Security audit: `npm audit` / `cargo audit` / `pip-audit`
   - Secret scan: grep for API_KEY, SECRET, PASSWORD, TOKEN patterns in source
     (exclude node_modules, target, .git, .env)
   - Git hygiene: stale branches (merged or >30 days), remote divergence
   - Environment: required tools present and correct versions

3. REPORT:

   ## Doctor Report: [project name]

   ### Health: Healthy / Needs Attention / Broken

   ### Critical (fix now)
   - Finding + fix command

   ### Warnings (fix soon)
   - Finding + recommendation

   ### Info
   - Dependency count, test coverage (if available), tool versions

   ### Recommended Actions (prioritized)
   1. Highest priority
   2. ...

Rules:

- Run actual commands — don't guess
- Don't auto-fix anything — report and recommend
- For "all" scope: run against each project independently, then summarize
