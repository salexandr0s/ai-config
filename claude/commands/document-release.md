Post-ship documentation sync — ensure docs match reality after a release.

$ARGUMENTS

---

## Process

### Step 1: Gather Changes

```bash
# Recent changes since last tag
git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || echo "HEAD~20")..HEAD
# Changed files
git diff --name-only $(git describe --tags --abbrev=0 2>/dev/null || echo "HEAD~20")..HEAD
```

Read the output to understand what shipped.

### Step 2: Audit Each Document

Check each of these (if they exist) for accuracy:

| Document           | Check For                                        |
|--------------------|--------------------------------------------------|
| `README.md`        | Install steps, usage examples, feature list       |
| `ARCHITECTURE.md`  | Component descriptions, diagrams, data flows      |
| `CONTRIBUTING.md`  | Dev setup, PR process, code style                 |
| `CLAUDE.md`        | Commands, verification steps, project conventions  |
| `CHANGELOG.md`     | Entries match actual changes                       |
| `docs/`            | API docs, guides, tutorials                        |

For each document:
1. Read the current version
2. Compare against the actual state of the code
3. Note specific inaccuracies (outdated paths, changed CLI output, removed features, new features not documented)

### Step 3: Apply Factual Corrections

Fix objective errors without asking:
- Updated CLI output or command syntax
- Changed file paths or directory structure
- New features that are clearly documented in code but missing from docs
- Removed features still mentioned in docs
- Version numbers and dependency versions

### Step 4: Ask About Narrative Changes

For subjective or philosophical changes, ask the user:
- Philosophy shifts ("we now prefer X over Y")
- Security posture changes
- Major feature removals that affect the project's story
- Audience or scope changes

### Step 5: CHANGELOG Polish

**ONLY use Edit** (never Write) for CHANGELOG modifications:
- Word adjustments only — do not restructure
- Ensure entries match actual changes
- Fix typos, clarify descriptions
- Do NOT add entries for this documentation update itself

### Step 6: Cross-Document Consistency

Verify:
- Version numbers match across all docs
- Internal links resolve (relative paths work)
- Feature names are consistent
- No contradictions between documents

### Step 7: TODOS.md Cleanup

If `TODOS.md` or `TODO.md` exists:
- Mark items completed by recent changes
- Flag items that are stale (> 3 months, no related activity)
- Do NOT delete items — mark them

### Step 8: VERSION Decision

Ask the user:
- "Based on these changes, what version bump? (major/minor/patch/none)"
- Recommend based on semantic versioning rules
- If they choose a bump: update version in package.json, Cargo.toml, pyproject.toml, or wherever version is stored

### Step 9: Commit + PR Update

- Stage all documentation changes
- Suggest commit message: `docs: sync documentation with {version/release}`
- If a PR exists for this release, suggest updating its body with the doc changes

---

## Rules

- Use Edit for all changes — never Write (prevents accidental full-file overwrites)
- Do NOT add documentation for this command itself
- Do NOT restructure existing docs — fix inaccuracies only
- Be specific in commit messages about what was updated
