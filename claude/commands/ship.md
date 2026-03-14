Automated pre-merge pipeline. Verify, review, version, and create a PR.

$ARGUMENTS

## Phase 1: Sync & Verify

1. Confirm NOT on main/master branch. STOP if on default branch.
2. Fetch and rebase on the base branch: `git fetch origin && git rebase origin/main`
3. Run `dev-verify` (lint + typecheck + tests). STOP on failure — fix first.

## Phase 2: Pre-Merge Review

Self-review all changes (`git diff origin/main...HEAD`):

- BLOCKER: debug prints (console.log used for debugging), hardcoded secrets, .env files, conflict markers (`<<<<<<<`)
- WARNING: TODOs without ticket references, large functions (>50 lines added), missing tests for new behavior

Report findings. STOP on any BLOCKER — fix before continuing.

## Phase 3: Version & Changelog

1. Analyze commit types since divergence from base:
   - `feat` → minor bump
   - `fix` → patch bump
   - `BREAKING CHANGE` or `!` in type → major bump
2. If `package.json` exists, bump the version field
3. If `CHANGELOG.md` exists, prepend an entry:
   ```
   ## [x.y.z] - YYYY-MM-DD
   ### Added / Changed / Fixed
   - entries from commits
   ```
4. GATE: Present version + changelog to user for approval. Do NOT proceed without approval.

## Phase 4: Commit Hygiene

1. Check for WIP/fixup/squash commits: `git log --oneline origin/main..HEAD | grep -iE '^[a-f0-9]+ (wip|fixup|squash)'`
2. If found, recommend interactive rebase (tell user, don't do it automatically)
3. Commit version bump + changelog (if any): `chore(release): bump to x.y.z`

## Phase 5: Create PR

1. Push branch: `git push -u origin HEAD`
2. Create PR with `gh pr create`:
   - Title from primary change type
   - Body: summary grouped by commit type, test plan, breaking changes note
3. Return PR URL

## Rules

- Never run on main/master
- Never force-push
- User approval required for version bump (Phase 3 gate)
- Stop on failing checks — do not skip verification
- If no package.json or CHANGELOG.md, skip versioning (Phase 3) entirely
