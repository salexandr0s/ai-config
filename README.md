# ai-config

Shared configuration for AI coding assistants — [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Codex CLI](https://github.com/openai/codex). One repo, symlinked into each tool's config directory. Both tools share the same 8 agents, 6 core workflows, and workspace standards. The repo also includes a Claude `/config-editor` command with a matching Codex `config-editor` skill.

## Structure

```
ai-config/
├── claude/                          # Claude Code configuration
│   ├── agents/                      # 8 agent definitions (.md)
│   │   ├── team-lead.md
│   │   ├── researcher.md
│   │   ├── planner.md
│   │   ├── coder.md
│   │   ├── reviewer.md
│   │   ├── review-fix.md
│   │   ├── phase-implementer.md
│   │   └── ball-buster.md
│   ├── commands/                    # 31 slash commands + 6 workflow commands
│   │   ├── workflow-feature.md
│   │   ├── workflow-bugfix.md
│   │   ├── workflow-refactor.md
│   │   ├── workflow-review-only.md
│   │   ├── workflow-blind-review.md
│   │   ├── workflow-ball-buster-party.md
│   │   ├── commands.md              # Command reference table
│   │   └── ... (25 more commands)
│   ├── skills/
│   │   └── visual-explainer/        # HTML visualization skill (diagrams, slides, diffs)
│   ├── uiux-contract/              # Design system for agent-built UIs
│   │   ├── agent_contract.yaml      # High-level design rules
│   │   ├── design_tokens.json       # Colors, spacing, typography, motion (light + dark)
│   │   ├── quality_gates.yaml       # 6 blocker + 4 major self-check gates
│   │   ├── components/              # 11 component specs (button, input, modal, etc.)
│   │   └── schemas/                 # JSON schemas for tokens and contracts
│   ├── hooks.json                   # Auto-format on save, publish warnings
│   ├── mcp.example.json             # MCP servers: Playwright, Context7, shadcn
│   └── settings.example.json        # Permissions, env flags, effort level
├── codex/                           # Codex CLI configuration
│   ├── agents/                      # 8 agent definitions (.toml)
│   │   ├── team-lead.toml
│   │   ├── researcher.toml
│   │   ├── planner.toml
│   │   ├── coder.toml
│   │   ├── reviewer.toml
│   │   ├── review-fix.toml
│   │   ├── phase-implementer.toml
│   │   └── ball-buster.toml
│   ├── workflows/                   # 6 core workflow prompt templates
│   │   ├── feature.md
│   │   ├── bugfix.md
│   │   ├── refactor.md
│   │   ├── review-only.md
│   │   ├── blind-review.md
│   │   └── ball-buster-party.md
│   ├── skills/
│   │   └── config-editor/           # Codex skill for AI config audit/edit/parity checks
│   ├── rules/
│   │   └── default.rules            # Command approval rules (Starlark)
│   └── config.example.toml          # Full config with multi-agent setup
├── shared/
│   └── CLAUDE.md                    # Workspace-level standards (→ ~/GitHub/CLAUDE.md)
└── install.sh                       # Symlink installer (idempotent, backs up existing)
```

---

## Installation

```bash
git clone https://github.com/salexandr0s/ai-config.git ~/GitHub/ai-config
cd ~/GitHub/ai-config
./install.sh
```

The installer creates symlinks from each tool's config directory into this repo. Existing files are backed up with a timestamp suffix. Re-running is safe and idempotent.

### What gets symlinked

| Source                           | Target                              |
| -------------------------------- | ----------------------------------- |
| `claude/agents/`                 | `~/.claude/agents/`                 |
| `claude/commands/`               | `~/.claude/commands/`               |
| `claude/uiux-contract/`          | `~/.claude/uiux-contract/`          |
| `claude/hooks.json`              | `~/.claude/hooks.json`              |
| `claude/skills/visual-explainer` | `~/.claude/skills/visual-explainer` |
| `codex/agents/`                  | `~/.codex/agents/`                  |
| `codex/rules/`                   | `~/.codex/rules/`                   |
| `codex/skills/config-editor`     | `~/.codex/skills/config-editor`     |
| `shared/CLAUDE.md`               | `~/GitHub/CLAUDE.md`                |

### Manual setup (not symlinked)

These contain personal settings — copy and customize:

```bash
cp claude/settings.example.json ~/.claude/settings.json
cp claude/mcp.example.json ~/.claude/.mcp.json
cp codex/config.example.toml ~/.codex/config.toml
```

---

## Agents

Both tools share the same 8-agent roster with identical roles. Claude Code agents are defined in Markdown (`.md`), Codex agents in TOML (`.toml`).

| Agent               | Role                                                             | Writes code | Sandbox (Codex)   |
| ------------------- | ---------------------------------------------------------------- | ----------- | ----------------- |
| `team-lead`         | Orchestrates teams, manages phases and gates                     | No          | `read-only`       |
| `researcher`        | Read-only codebase explorer — maps architecture and dependencies | No          | `read-only`       |
| `planner`           | Designs implementation plans with steps and testing              | No          | `read-only`       |
| `coder`             | Implements approved plans, runs verification checks              | Yes         | `workspace-write` |
| `reviewer`          | Critiques plans and reviews code (Must Fix / Should Fix / Nits)  | No          | `read-only`       |
| `review-fix`        | Reviews code and autonomously patches safe issues                | Yes         | `workspace-write` |
| `phase-implementer` | Self-plans and executes a scoped task without team overhead      | Yes         | `workspace-write` |
| `ball-buster`       | Brutally honest codebase critic — questions every decision       | No          | `read-only`       |

### Agent categories

- **Read-only** (team-lead, researcher, planner, reviewer, ball-buster) — explore, plan, and critique without modifying files
- **Write-capable** (coder, review-fix, phase-implementer) — implement changes and run verification
- **Autonomous** (review-fix, phase-implementer) — self-direct within defined boundaries without needing team coordination

---

## Workflows

Six predefined multi-agent workflows are available in both tools:

| Workflow              | Phases                                                       | Approval gate    | Fix cycles |
| --------------------- | ------------------------------------------------------------ | ---------------- | ---------- |
| **feature**           | research → plan → implement → review → closeout              | Before implement | Max 3      |
| **bugfix**            | investigate → fix → review → closeout                        | None             | Max 2      |
| **refactor**          | map impact → plan → review plan → implement → review → close | Before implement | Max 2      |
| **review-only**       | explore → review → report                                    | N/A (read-only)  | N/A        |
| **blind-review**      | 3 parallel reviewers → combine → validate                    | N/A (read-only)  | N/A        |
| **ball-buster-party** | scout → parallel ball-busters (1 per feature) → combine      | N/A (read-only)  | N/A        |

### Config Audit Capability

Claude Code provides this as a slash command:

```
/config-editor
/config-editor apply
```

Codex provides the equivalent as a skill:

```bash
codex "$config-editor audit the current AI config"
codex "$config-editor audit the current AI config and apply fixes"
```

### Usage

**Claude Code** — workflows are slash commands:

```
/workflow-feature add dark mode toggle to the settings page
/workflow-bugfix login fails when email contains a plus sign
/workflow-refactor extract auth logic into a shared module
/workflow-review-only the authentication module
/workflow-blind-review
/workflow-ball-buster-party the entire frontend
```

**Codex CLI** — workflows are prompt templates:

```bash
codex "Follow the workflow in workflows/feature.md to implement: dark mode toggle"
codex "Follow the workflow in workflows/bugfix.md to fix: login plus sign bug"
codex "Follow the workflow in workflows/refactor.md to refactor: extract auth module"
codex "Follow the workflow in workflows/review-only.md to review: auth module"
codex "Follow the workflow in workflows/blind-review.md to blind-review changes"
codex "Follow the workflow in workflows/ball-buster-party.md to roast: the frontend"
```

---

## Slash Commands

37 slash commands available in Claude Code. Run `/commands` to see the full reference.

| Category          | Commands                                                                                                                      |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Workflows**     | workflow-feature, workflow-bugfix, workflow-refactor, workflow-review-only, workflow-blind-review, workflow-ball-buster-party |
| **Planning**      | spec, interview, dod, reqwording, storygen, phase                                                                             |
| **Quality**       | closeout, lint, test, deploy-check, fact-check, condense                                                                      |
| **Config**        | config-editor                                                                                                                  |
| **Security**      | auditdeep, securecoding, threatmodel, supplychain, green                                                                      |
| **Operations**    | debug, refactor, focus, doctor, release, pr                                                                                   |
| **Documentation** | adr, postmortem, handoff, visualize                                                                                           |
| **Project**       | new-project, commands, openclaw-triage                                                                                        |

---

## Hooks

`claude/hooks.json` configures two Claude Code hooks:

- **PostToolUse** (Write/Edit/NotebookEdit) — auto-formats saved files with Prettier (JS/TS) or Ruff (Python)
- **PreToolUse** (Bash) — warns before commands that publish externally (`npm publish`, `git tag`, `docker push`)

---

## MCP Servers

`claude/mcp.example.json` configures three MCP plugins:

| Plugin         | Purpose                            |
| -------------- | ---------------------------------- |
| **Playwright** | Browser automation and E2E testing |
| **Context7**   | Up-to-date library documentation   |
| **shadcn**     | Component registry browse/install  |

---

## Codex Rules

`codex/rules/default.rules` defines command-level permissions using Starlark `prefix_rule()` syntax. Rules are evaluated most-restrictive-wins: `forbidden > prompt > allow`.

| Decision      | Applies to                                                                                                                                           |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **forbidden** | Destructive operations — force push, rm -rf, sudo, dd, mkfs, killall, npm unpublish                                                                  |
| **allow**     | Safe dev tools — git (non-destructive), npm, node, linters, test runners, file utilities, Docker (non-destructive), dev-verify/dev-format/dev-status |

---

## Codex Multi-Agent Config

`codex/config.example.toml` includes the full multi-agent setup:

```toml
[features]
multi_agent = true

[agents]
max_threads = 6          # Max concurrent agent threads
max_depth = 1            # Agent nesting depth
job_max_runtime_seconds = 1800   # 30-minute timeout per agent job

[agents.<name>]
description = "..."
config_file = "agents/<name>.toml"
```

Each agent TOML defines: `model`, `model_reasoning_effort`, `sandbox_mode`, and `developer_instructions`.

---

## UI/UX Design System

`claude/uiux-contract/` is a machine-readable design system (Apple Minimal) that agents must follow for any UI work:

| File                    | Purpose                                                                                               |
| ----------------------- | ----------------------------------------------------------------------------------------------------- |
| `agent_contract.yaml`   | High-level design rules and principles                                                                |
| `design_tokens.json`    | Colors, spacing, radii, shadows, typography, motion (light + dark modes)                              |
| `quality_gates.yaml`    | 6 blocker + 4 major self-check gates                                                                  |
| `components/*.yaml`     | 11 component specs (button, input, dropdown, modal, navbar, sidebar, table, tabs, toast, card, badge) |
| `schemas/*.schema.json` | JSON schemas for validation                                                                           |

Agents must never hardcode arbitrary visual values — all colors, spacing, radii, shadows, font sizes, and motion timings must use design tokens.

---

## Skills

### visual-explainer

Custom Claude Code skill for generating self-contained HTML visualizations:

- Architecture diagrams
- Slide decks
- Diff reviews
- Plan reviews
- Project recaps
- Data tables
- Fact-check reports

Includes Mermaid.js support, responsive templates, and CSS pattern references. Invoked via `/visualize <type>`.

---

## Shared Standards

`shared/CLAUDE.md` is the workspace-level instruction file symlinked to `~/GitHub/CLAUDE.md`. It governs all agent behavior across both tools:

- **Hard rules** — verification frequency, no mass renames, no blanket type suppressions, no weakening rules to pass checks
- **Session protocol** — start/end checklists, shared memory at `~/GitHub/.memory/`
- **Dev stack defaults** — TypeScript (strict), Next.js, Fastify, TailwindCSS, Radix UI, Zod, Prisma, Vitest, Playwright
- **Git conventions** — branch naming, conventional commits, small reviewable changes
- **Team workflow** — phase gates, user approval before implementation, verification before completion
- **Coding style** — strict mode, no `any`, Zod at boundaries, kebab-case files, named exports
- **UI/UX contract** — all UI work must follow design tokens and quality gates
- **Dev scripts** — `dev-verify`, `dev-format`, `dev-status` (auto-detect project type)
- **Secrets** — macOS Keychain vault (`claudecodex.keychain-db`), per-project `.env` files

---

## Settings

`claude/settings.example.json` configures:

- **Environment** — `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (enables team orchestration)
- **Permissions** — allow-list for all tools (Bash, Read, Edit, Write, Glob, Grep, WebFetch, WebSearch, Team/Task tools) and deny-list for destructive operations (force push, rm -rf, sudo, etc.)
- **Effort level** — `high`
