<!-- Source of truth: claude/commands/investigate.md -->

# Investigate Workflow

Systematic root-cause debugging with phased discipline.

## Phase 1: Investigate

- Spawn `researcher` agent to collect evidence
- Researcher reads code, logs, git history
- Researcher reproduces the bug if possible
- **Gate:** Evidence collected before analysis begins

## Phase 2: Analyze

- Researcher forms 2–4 hypotheses ranked by likelihood
- Pattern-match against known failure modes
- Check MEMORY/LEARNINGS for known patterns
- Present hypotheses to team lead

## Phase 3: Hypothesize

- Team lead presents hypotheses to user with confidence levels
- **Gate:** User approves root cause and fix approach before implementation
- 3-strike rule: if 3 hypotheses fail, STOP and escalate

## Phase 4: Implement

- Spawn `coder` agent with approved fix approach
- Coder writes regression test first (must fail before fix)
- Coder applies minimal fix
- Coder runs `dev-verify`

## Phase 5: Verify

- Spawn `reviewer` agent to verify:
  - Fix addresses root cause (not symptom)
  - Regression test is meaningful
  - No collateral damage
  - Verification passes
- Report: DONE / DONE_WITH_CONCERNS / BLOCKED
