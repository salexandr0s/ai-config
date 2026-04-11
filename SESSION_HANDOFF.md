# Session Handoff — 2026-04-11

## Completed
- Replaced the custom Claude/Codex bridge commands with the official OpenAI Claude Code Codex plugin locally.
- Installed and enabled `codex@openai-codex` from `openai/codex-plugin-cc` v1.0.3 locally.
- Removed the local active MCP entry for `claude-codex-bridge` from `~/.claude/.mcp.json`.
- Repeated the official plugin installation on `ssh savorgserver` by manually installing the marketplace/cache because `claude plugin list` and marketplace commands hang on that host.
- Updated `savorgserver` Codex CLI to `0.118.0` after plugin setup probes exposed app-server startup issues with the previous CLI; direct config install is complete.
- Created commits:
  - Local: `a8495cb chore(claude): replace codex bridge with official plugin`
  - Remote `savorgserver`: `1e90646 chore(claude): enable official codex plugin`

## Key Files Changed
- Local `claude/settings.json` — enables `codex@openai-codex` and declares the `openai-codex` marketplace.
- Local `claude/commands/codexplan.md` — deleted old bridge command.
- Local `claude/commands/codexreview.md` — deleted old bridge command.
- Local `claude/commands/codexsession.md` — deleted old bridge command.
- Local `~/.claude/.mcp.json` — removed `claude-codex-bridge` MCP server entry.
- Remote `~/.claude/plugins/marketplaces/openai-codex` — cloned official `openai/codex-plugin-cc` at `6a5c2ba53b734f3cdd8daacbd49f68f3e6c8c167`.
- Remote `~/.claude/plugins/cache/openai-codex/codex/1.0.3` — installed official plugin cache.
- Remote `~/.claude/plugins/{known_marketplaces.json,installed_plugins.json}` — registered `openai-codex` and `codex@openai-codex`.
- Remote `~/GitHub/ai-config/claude/settings.json` — enables `codex@openai-codex` and declares the marketplace.

## Verification State
- Local `dev-verify --quick` could not run because `/Users/nationalbank/GitHub/ai-config` has no root-level project manifest.
- Local targeted fallback passed:
  - JSON parse for Claude settings, MCP config, known marketplaces, and installed plugins.
  - `bash -n` for `install.sh` and `scripts/*.sh`.
  - Confirmed old bridge command files are absent.
  - Confirmed no active old bridge references in Claude settings, MCP config, command directory, or plugin registries.
  - `node ~/.claude/plugins/cache/openai-codex/codex/1.0.3/scripts/codex-companion.mjs setup --json` returned ready/authenticated locally.
- Remote targeted fallback passed:
  - JSON parse for remote Claude settings, MCP config, known marketplaces, and installed plugins.
  - `bash -n` for remote `install.sh` and `scripts/*.sh`.
  - Confirmed old bridge command files are absent.
  - Confirmed official plugin cache has all expected commands.
  - Confirmed no active old bridge references in remote active config surfaces.
  - Confirmed `codex login status` reports logged in on `savorgserver`.

## Remaining / Known Gaps
- On `savorgserver`, `claude plugin list` / marketplace commands time out, so the official plugin was installed by directly updating Claude plugin cache/registry files instead of using the Claude plugin CLI.
- On `savorgserver`, direct `codex app-server` initialization hangs when using the existing `~/.codex/auth.json`; it initializes with a temporary empty `CODEX_HOME`, which points to a remote Codex auth/app-server issue rather than a plugin file installation issue.
- Remote `~/GitHub/ai-config` still has pre-existing untracked `browse/bun.lock`; it was not touched or committed.
- Active Claude sessions may need `/reload-plugins` before `/codex:*` commands appear.

## Resume Commands
- Local status: `git -C ~/GitHub/ai-config status --short --branch && claude plugin list --json | python3 -m json.tool`
- Local setup check: `node ~/.claude/plugins/cache/openai-codex/codex/1.0.3/scripts/codex-companion.mjs setup --json`
- Remote status: `ssh savorgserver 'git -C ~/GitHub/ai-config status --short --branch; codex --version; codex login status'`
- Remote plugin registry check: `ssh savorgserver 'python3 -m json.tool ~/.claude/plugins/installed_plugins.json >/dev/null && python3 -m json.tool ~/.claude/plugins/known_marketplaces.json >/dev/null'`
- Remote app-server diagnosis: `ssh savorgserver 'CODEX_HOME=$(mktemp -d) codex app-server'` and compare with normal `codex app-server` initialization.

## Decisions Made
- Used the official OpenAI marketplace/plugin identity: `openai-codex` / `codex@openai-codex`.
- Removed active custom bridge surfaces instead of deleting the clean local `~/GitHub/claude-codex-bridge` source repo; the old repo is inactive but still available if recovery is needed.
- Kept backups under `~/.claude/backups/codex-plugin-replace-*` before editing config.
