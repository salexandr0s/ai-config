<!-- Source of truth: claude/commands/investigate.md -->

# Investigate Workflow

Systematic root-cause debugging with phased discipline.

## Phase 1: Investigate

- Spawn `researcher` agent to collect evidence
- Researcher reads code, logs, git history
- Researcher reproduces the bug if possible
- Researcher states whether the bug is simple or non-simple under the Bug Handling rules
- **Gate:** Evidence collected before analysis begins

## Phase 2: Analyze

- Researcher forms 2–4 hypotheses ranked by likelihood
- Pattern-match against known failure modes
- Check MEMORY/LEARNINGS for known patterns
- Present hypotheses with confidence levels and evidence for/against

## Phase 3: Hypothesize

- Team lead presents the leading root cause, proposed fix, and confidence level to the user
- **Gate:** User approves root cause and fix approach before implementation
- 3-strike rule: if 3 hypotheses fail, STOP and escalate

## Phase 4: Implement

- Spawn `coder` agent with approved fix approach
- Coder reuses an existing reproducer or adds a focused regression test when a meaningful recurrence risk remains uncovered under the shared Testing policy
- Coder applies the narrowest reviewer-acceptable fix at the root cause
- Coder runs focused checks for the fix and affected dependencies under the shared Verification policy

## Phase 5: Verify

- Spawn `reviewer` agent to verify:
  - Fix addresses root cause (not symptom)
  - Selected reproduction check is meaningful; any added regression test fails without the fix
  - Confidence level still matches the evidence
  - No collateral damage
  - Verification or targeted fallback passes
- Report: DONE / DONE_WITH_CONCERNS / BLOCKED
