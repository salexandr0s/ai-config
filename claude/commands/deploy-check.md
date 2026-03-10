Run pre-deployment verification for the current project. Do NOT actually deploy — just verify readiness.

1. Check git status:
   - Are there uncommitted changes?
   - What branch are we on?
   - Are we up to date with remote?
2. Run the full quality gate:
   - Lint (no new warnings)
   - Type-check (must pass)
   - Tests (must pass)
   - Build (`npm run build` or equivalent — must succeed)
3. Check for common deployment issues:
   - `.env.example` exists if `.env` is used
   - No hardcoded localhost URLs in source
   - No `console.log` statements (warn only)
   - No TODO/FIXME comments in changed files (warn only)
4. Summarize: READY or NOT READY with a list of blocking issues
