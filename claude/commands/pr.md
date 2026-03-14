Create a pull request for the current branch.

$ARGUMENTS

1. Check git status and identify the base branch (main or dev)
2. Run `git log --oneline $(git merge-base HEAD origin/main)..HEAD` to see all commits on this branch
3. Run `git diff origin/main...HEAD --stat` to see the full scope of changes
   3b. Pre-flight checks: - Run `dev-verify --quick` (lint + typecheck must pass) - Check for TODO/FIXME in changed files (warn, don't block) - Check for .env or credential files in the diff (block if found)
4. Draft a PR title (short, under 70 chars) and body:
   - Summary: 1-3 bullet points of what changed and why
   - Test plan: how to verify the changes work
   - Breaking changes: note any breaking changes with migration steps
5. If there are uncommitted changes, ask whether to commit them first
6. Push the branch and create the PR with `gh pr create`
7. Return the PR URL
