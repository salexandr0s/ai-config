# Session Handoff — 2026-10-09

## Latest Work — Avoid AI Writing
- Vendored the complete skill package from `salexandr0s/avoid-ai-writing` commit `1416dfd0388fb338f43d248d5f262fa44eefe4b2` (skill version 3.37.0) into `shared/skills/avoid-ai-writing/`, excluding Git metadata and `.gitignore`. All 15 payload files and modes match the source except four removed trailing-whitespace spans in `detector/patterns.js`. LICENSE and NOTICE.md are preserved.
- Added relative directory aliases at `claude/skills/avoid-ai-writing` and `codex/skills/avoid-ai-writing`, both pointing to the same shared package. Added global link steps to `install.sh` and installed the two live skill links.
- Documented provenance, updates, Node.js >=18, fresh-chat loading, and invocation in README.md. Claude: `/avoid-ai-writing`; Codex: `$avoid-ai-writing`. Preserved Codex's explicit-invocation policy.
- Passed bash syntax, ShellCheck, diff whitespace, all five Node.js syntax checks, both JSON example parses, detector smoke checks, preservation/style/quote CLI checks, and global-link checks. Repeated the two new installer link steps successfully to verify idempotency. The upstream preservation sample reports a non-blocking large-shrink warning.
- Codex native `skills/list` discovery with a fresh scan confirms exactly one enabled `avoid-ai-writing` user skill from both `~/GitHub` and `~/GitHub/ai-config`, with no package load errors.
- `dev-verify --quick` and `dev-verify` cannot detect this configuration repository; targeted checks above are the fallback. No root type-checker is configured.
- Existing user changes in `claude/settings.json` and `codex/rules/default.rules` remain untouched. No remote push was performed.

## Key Files Changed
- `shared/skills/avoid-ai-writing/` — shared package, scripts, references, examples, and notices.
- `claude/skills/avoid-ai-writing`, `codex/skills/avoid-ai-writing` — relative aliases.
- `install.sh`, `README.md`, `SESSION_HANDOFF.md` — installation and documentation.

## Latest Resume Commands
- `git status --short --branch`
- `bash -n install.sh && shellcheck install.sh`
- `git diff --check`
- `node --check shared/skills/avoid-ai-writing/detector/patterns.js`

## Latest Decisions
- Keep one shared vendored package so Claude and Codex cannot drift; the only local adjustment is trailing-whitespace cleanup.
- Apply only the new skill link steps locally; avoid unrelated installer side effects.
- Start a fresh Claude/Codex chat to load the new skill.
- The upstream detector comment defers POS-bigram log-odds and function-word z-scores; these optional upstream features remain outside this installation's scope.

## Previous Work — Hooks (2026-10-08)

## Completed
- Registered native Claude hooks directly in settings.json; removed the obsolete standalone hook file and its managed home symlink. Installer and upgrade metadata now match.
- Fixed stdin JSON inputs, timeout seconds, freeze path handling, formatter error reporting, and session/tool IDs. Formatting uses installed tools and precedes change tracking; interactive title updates use terminalSequence JSON.
- Replaced raw-text command guards with a shared literal-command scanner. Claude requests native approval; Codex retains denial for actual matched risky commands because its installed protocol cannot request approval. Quoted examples and dry-run/read-only operations stay quiet.
- Added shared final verification for Claude and Codex. It tracks direct edits and shell writes, catches writes with missing post callbacks and edits committed in the same call, ignores commit-only pre-existing user changes, and checks only after code changed.
- Final checks include diff whitespace/conflict checks (including new untracked files), existing quick project checks, and touched shell/Python/JSON/TOML syntax. Missing tools are reported; no automatic dependency installs.
- Added Claude attention notifications using the existing ai-notify sound/cooldown. Completion sounds wait for final verification; session metadata logging now runs at SessionEnd as compact JSONL.
- Added disposable-home/repository regression tests. No deployment, network-install, real notification, or user-file formatter commands were executed by tests.

## Verification State
- Run `python3 -B -m unittest discover -s tests -v` for all hook regression tests.
- ShellCheck, bash syntax, Python AST parsing, hook/config JSON parsing, and diff whitespace checks passed.
- This repository has no root-level JS/TS/Python/Rust project manifest or unified verify entrypoint; targeted hook tests and syntax checks are the verification fallback. No root type-checker is configured.
- Independent review identified the same-call edit-and-commit gap; regression coverage and Git baseline tracking address it. The reviewer approved the corrected verifier.

## Remaining / Known Gaps
- Start fresh Claude/Codex chats to load the new hook registrations. Review/approve new Codex hook commands through `/hooks` if prompted; existing conversations may retain their startup snapshot.
- Codex 0.154.0 does not support hook permissionDecision ask, so matched production/infrastructure/database commands remain denied there. Claude supports native approval requests.
- Guard scanning cannot resolve dynamically constructed commands, aliases, arbitrary scripts/interpreter code, or remote commands. Shell repository discovery supports explicit workdir/cwd, cd, and git -C rather than scanning home.
- Pre-existing user changes to Claude settings and Codex rules were preserved and excluded from the hook commit. The terminal-config working tree was left unchanged.
- Previous savorgserver plugin CLI/app-server issues recorded in the April handoff were not investigated or changed in this local task; that handoff remains in Git history.

## Resume Commands
- `git status --short --branch`
- `python3 -B -m unittest discover -s tests -v`
- `git diff --check`

## Decisions Made
- Keep one native Claude configuration source instead of duplicating hooks across files.
- Use standard-library Python plus existing shell/jq tools, session-local state, bounded check timeouts/retries, and installed project checkers. No new dependency or hook framework.
- Preserve unrelated edits when staging settings.json by committing the hook block against HEAD independently of those existing changes.
