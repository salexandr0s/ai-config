# ai-config

Shared configuration for AI coding assistants — [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Codex CLI](https://github.com/openai/codex). One repo, symlinked into each tool's config directory.

## Structure

```
ai-config/
├── claude/                     # Claude Code configuration
│   ├── agents/                 # 7 agent definitions (team-lead, researcher, planner, coder, reviewer, review-fix, phase-implementer)
│   ├── commands/               # 35 slash commands + 5 workflow commands
│   ├── hooks.json              # Auto-format on save, publish warnings
│   ├── skills/                 # Custom skills (visual-explainer)
│   ├── uiux-contract/          # Design system tokens, component specs, quality gates
│   ├── mcp.example.json        # MCP server config (copy + customize)
│   └── settings.example.json   # Editor settings (copy + customize)
├── codex/                      # Codex CLI configuration
│   ├── agents/                 # 4 agent definitions (explorer, planner, reviewer, worker)
│   ├── rules/                  # Command approval rules (allow/prompt/forbidden)
│   ├── workflows/              # 5 workflow prompt templates
│   └── config.example.toml     # Full config with multi-agent setup (copy + customize)
├── shared/
│   └── CLAUDE.md               # Workspace-level standards (symlinked to ~/GitHub/CLAUDE.md)
└── install.sh                  # Symlink installer
```

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
| `codex/rules/`                   | `~/.codex/rules/`                   |
| `shared/CLAUDE.md`               | `~/GitHub/CLAUDE.md`                |

### Manual setup (not symlinked)

These contain personal settings — copy and customize:

```bash
cp claude/settings.example.json ~/.claude/settings.json
cp claude/mcp.example.json ~/.claude/.mcp.json
cp codex/config.example.toml ~/.codex/config.toml
```

## Agents

### Claude Code (8 agents)

| Agent               | Role                                                            | Writes code |
| ------------------- | --------------------------------------------------------------- | ----------- |
| `team-lead`         | Orchestrates teams, manages phases and gates                    | No          |
| `researcher`        | Read-only codebase explorer                                     | No          |
| `planner`           | Designs implementation plans with steps and testing             | No          |
| `coder`             | Implements approved plans                                       | Yes         |
| `reviewer`          | Critiques plans and reviews code (Must Fix / Should Fix / Nits) | No          |
| `review-fix`        | Reviews and autonomously patches safe issues                    | Yes         |
| `phase-implementer` | Self-plans and executes a scoped task without team overhead     | Yes         |
| `ball-buster`       | Brutally honest codebase critic — questions every decision      | No          |

### Codex CLI (8 agents)

| Agent               | Maps to Claude's    | Sandbox           |
| ------------------- | ------------------- | ----------------- |
| `team-lead`         | `team-lead`         | `read-only`       |
| `researcher`        | `researcher`        | `read-only`       |
| `planner`           | `planner`           | `read-only`       |
| `coder`             | `coder`             | `workspace-write` |
| `reviewer`          | `reviewer`          | `read-only`       |
| `review-fix`        | `review-fix`        | `workspace-write` |
| `phase-implementer` | `phase-implementer` | `workspace-write` |
| `ball-buster`       | `ball-buster`       | `read-only`       |

## Workflows

Six predefined multi-agent workflows available in both tools:

| Workflow              | Phases                                                       | Approval gate    | Fix cycles |
| --------------------- | ------------------------------------------------------------ | ---------------- | ---------- |
| **feature**           | research → plan → implement → review → closeout              | Before implement | Max 3      |
| **bugfix**            | investigate → fix → review → closeout                        | None             | Max 2      |
| **refactor**          | map impact → plan → review plan → implement → review → close | Before implement | Max 2      |
| **review-only**       | explore → review → report                                    | N/A (read-only)  | N/A        |
| **blind-review**      | 3 parallel reviewers → combine → validate                    | N/A (read-only)  | N/A        |
| **ball-buster-party** | scout → parallel ball-busters (1 per feature) → combine      | N/A (read-only)  | N/A        |

### Usage

**Claude Code** — workflows are slash commands:

```
/workflow-feature add dark mode toggle to the settings page
/workflow-bugfix login fails when email contains a plus sign
/workflow-refactor extract auth logic into a shared module
```

**Codex CLI** — workflows are prompt templates:

```bash
codex "Follow the workflow in workflows/feature.md to implement: dark mode toggle"
codex "Follow the workflow in workflows/bugfix.md to fix: login plus sign bug"
```

## Slash Commands

Run `/commands` in Claude Code to see the full list. Categories:

- **Workflows** — multi-agent orchestrated flows (feature, bugfix, refactor, review-only, blind-review)
- **Planning** — spec, interview, dod, reqwording, storygen, phase
- **Quality** — closeout, lint, test, deploy-check, fact-check, condense
- **Security** — auditdeep, securecoding, threatmodel, supplychain, green
- **Operations** — debug, refactor, focus, doctor, release, pr
- **Documentation** — adr, postmortem, handoff, visualize
- **Project** — new-project, commands, openclaw-triage

## Codex Rules

`codex/rules/default.rules` defines command-level permissions using Starlark syntax:

- **`forbidden`** — destructive operations (force push, rm -rf, sudo, etc.)
- **`allow`** — safe dev tools (git, npm, linters, test runners, file utilities)

Rules are evaluated most-restrictive-wins: `forbidden > prompt > allow`.

## Shared Standards

`shared/CLAUDE.md` is the workspace-level instruction file symlinked to `~/GitHub/CLAUDE.md`. It defines:

- Hard rules for all agents (verification frequency, no mass renames, no blanket suppressions)
- Session protocol (start/end checklists, shared memory)
- Default dev stack (TypeScript, Next.js, Fastify, TailwindCSS, Vitest)
- Git conventions and commit format
- Team workflow phases and gates
- UI/UX design system contract
