<!-- Source of truth: claude/commands/ship.md — keep phases and rules in sync -->

# Pre-Merge Ship Pipeline

Use this prompt template for automated pre-merge verification and PR creation.

## Usage

```
codex "Follow the workflow in workflows/ship.md to ship the current branch"
```

## Workflow

You are running a pre-merge pipeline. Verify, review, version, and create a PR.

### Phase 1: Sync & Verify

1. Confirm NOT on main/master. STOP if on default branch.
2. Fetch and rebase: `git fetch origin && git rebase origin/main`
3. Confirm the applicable checks selected under the shared Testing, Verification, and CI policies passed for this revision. Run missing or invalidated checks; use full `dev-verify` only when risk or required gates justify it. STOP on failures caused by the change or a failing required gate.

### Phase 2: Pre-Merge Review

Self-review `git diff origin/main...HEAD`:

- BLOCKER: debug prints, secrets, .env files, conflict markers
- WARNING: TODOs without tickets, large functions, concrete failure risks missing useful coverage

STOP on any BLOCKER.

### Phase 3: Version & Changelog

1. Determine bump from commit types (feat→minor, fix→patch, BREAKING→major)
2. Bump package.json if exists
3. Prepend CHANGELOG entry if exists
4. Ask user to approve version + changelog before continuing

### Phase 4: Commit & PR

1. Check for WIP/fixup commits — recommend squash if found
2. Commit version bump if any
3. Push branch and create PR with `gh pr create`
4. Return PR URL

## Rules

- Never on main/master
- Never force-push
- User approval for version bump
- Stop on failures caused by the change or a failing required gate; report unrelated existing failures without treating them as additional blockers
- Keep the review scoped to the diff; broad manual audits before or after the PR require an affected risk or explicit request.
