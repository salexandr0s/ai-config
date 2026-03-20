<!-- Source of truth: claude/commands/document-release.md -->

# Document-Release Workflow

Post-ship documentation sync for Codex agent teams.

## Phase 1: Context Gathering

- Spawn `researcher` agent to gather change context
- Read git log since last tag/release
- Identify all changed files and their impact on documentation

## Phase 2: Documentation Edits

- Spawn `coder` agent to make doc edits
- Apply factual corrections (paths, CLI output, features)
- Ask user about narrative/philosophical changes
- CHANGELOG polish (Edit only, word adjustments)

## Phase 3: Verification

- Spawn `reviewer` agent to verify consistency
- Check cross-document version numbers
- Verify internal links resolve
- Confirm no contradictions between documents
- Report any remaining inaccuracies
