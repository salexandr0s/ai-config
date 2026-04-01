# Session Handoff — 2026-04-01

## Completed
- Hardened `shared/CLAUDE.md` with dual-mode quality posture and explicit targeted-verification fallback when `dev-verify` is unavailable.
- Tightened Claude and Codex agent prompts so write-capable and review-capable agents now enforce rereads, bounded phases, Step 0 cleanup, rename/search coverage, and stronger verification language.
- Updated Claude/Codex feature, refactor, bugfix, and investigate workflows to require bounded phases, explicit fallback verification, and stronger root-cause discipline.
- Added Claude post-edit verification hook via `scripts/claude-post-edit-verify.sh` and wired it into `claude/hooks.json` after the formatter hook.
- Enabled Codex hooks in `codex/config.base.toml`, added `codex/hooks.json`, and added Bash-only Codex hook scripts for pre-command guarding and post-command verification reminders.
- Updated `install.sh` and `README.md` so the installer and docs match the new hook/enforcement model.
- Ran `./install.sh`, activated the Claude/Codex changes, and verified the live hook symlinks (`~/.claude/hooks.json`, `~/.codex/hooks.json`) point at this repo.
- Rendered the live Codex config and verified the generated `~/.codex/config.toml` parses and includes `codex_hooks = true`.

## Key Files Changed
- `shared/CLAUDE.md`
- `claude/agents/*.md` (coder, planner, reviewer, review-fix, phase-implementer, team-lead)
- `claude/commands/{workflow-feature,workflow-refactor,workflow-bugfix,investigate}.md`
- `claude/hooks.json`
- `codex/agents/*.toml` (coder, planner, reviewer, review-fix, phase-implementer, team-lead)
- `codex/workflows/{feature,refactor,bugfix,investigate}.md`
- `codex/config.base.toml`
- `codex/hooks.json`
- `scripts/{claude-post-edit-verify,codex-pre-bash-guard,codex-post-bash-review}.sh`
- `install.sh`
- `README.md`
- `SESSION_HANDOFF.md`

## Verification State
- Passed: `git diff --check`
- Passed: JSON parse of `claude/hooks.json` and `codex/hooks.json`
- Passed: TOML parse of `codex/config.base.toml` and all touched Codex agent TOMLs
- Passed: `bash -n` for `install.sh` and the touched shell scripts
- Passed: `./scripts/render-codex-config.sh` followed by TOML parse of `~/.codex/config.toml`
- Passed: hook smoke tests for:
  - `scripts/codex-pre-bash-guard.sh` warning output
  - `scripts/codex-post-bash-review.sh` additional-context output
  - `scripts/claude-post-edit-verify.sh` clean no-op behavior on this repo shape
- Not available: full repo-root `dev-verify`, because this repo has no single auto-detectable verify target at the root; targeted config/script validation was used instead.

## Remaining / Known Gaps
- Changes are uncommitted.
- Codex hooks are enabled, but current Codex runtime only emits Bash hook events; edit-time verification remains stronger on Claude than Codex.

## Resume Commands
- `cd /Users/nationalbank/GitHub/ai-config`
- `git status --short`
- `git diff --stat`
- `sed -n '1,120p' shared/CLAUDE.md`
- `sed -n '1,120p' claude/hooks.json`
- `sed -n '1,120p' codex/hooks.json`
- `sed -n '1,120p' codex/config.base.toml`

## Decisions Made
- `shared/CLAUDE.md` remains the canonical policy layer; agent prompts and workflows were aligned to it instead of inventing a second source of truth.
- Claude is the primary mechanical verification surface for post-edit JS/TS checks because Claude hooks can attach to `Write|Edit|NotebookEdit`.
- Codex hooks were enabled behind `codex_hooks = true`, but implementation stayed Bash-focused because current official Codex hook events are Bash-only.
- For this repo, targeted validation (JSON/TOML parse, `bash -n`, render smoke test) is the correct verification fallback instead of pretending `dev-verify` works at the repo root.
