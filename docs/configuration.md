# Installation and configuration

[Project overview](../README.md) · [Skill catalog](skills.md) · [Privacy review](privacy.md)

## Requirements

The setup is macOS-first. Core installation requires Bash, Git, and Python 3.11 or later. Install Claude Code, Codex, or both separately. The bundled writing tools use Node.js 18 or later. The configured shadcn MCP integration also needs a compatible Node/npm installation on PATH. Bun is optional and used only to build the browser daemon.

## Install

Clone the repository anywhere you keep source code, then run:

```sh
git clone https://github.com/salexandr0s/ai-config.git
cd ai-config
./install.sh
```

The installer links the reusable configuration, skills, commands, workflow templates, and shared resources. It creates missing local overlay templates and memory directories. Managed tool-link replacements are backed up outside active skill directories. Codex configuration is semantically merged, validated, and regenerated; it does not receive a byte-for-byte backup. Existing private overlays and personal context are preserved.

The default installation does not build the browser daemon or register a background job. Enable those separately:

```sh
./install.sh --with-browse
./install.sh --with-launchagent
```

`--with-browse` requires Bun and can download dependencies. `--with-launchagent` requires macOS and `launchctl`; it registers the weekly memory rotation job. `--skip-browse` and `--skip-launchagent` explicitly disable those optional steps.

### Choose a workspace

If `~/GitHub` exists, the installer links the shared workspace instructions there. Use a different workspace with:

```sh
mkdir -p "$HOME/Projects"
./install.sh --workspace "$HOME/Projects"
```

The managed repository alias is `${XDG_CONFIG_HOME:-$HOME/.config}/ai-config/repo`. Hook paths use this stable alias, so the checkout does not need to live at a hardcoded home-directory path. Re-run the installer after moving the checkout.

## Repository layout

```text
ai-config/
├── shared/
│   ├── skills/           Canonical shared skill packages
│   ├── CLAUDE.md         Workspace instructions for both assistants
│   └── assistant-ux.md   Shared response and status conventions
├── claude/
│   ├── agents/           Agent roles
│   ├── commands/         Slash commands
│   ├── skills/           Tool bindings and Claude-specific skills
│   ├── resources/        Review checklists
│   ├── uiux-contract/    Design tokens and component requirements
│   ├── user/             Blank personal-context templates
│   └── settings.json     Shared defaults and hook wiring
├── codex/
│   ├── agents/           Matching agent roles
│   ├── skills/           Tool bindings and Codex-specific skills
│   ├── workflows/        Installed workflow prompt templates
│   ├── rules/            Command approval rules
│   ├── instructions/     Response styles
│   └── config.base.toml  Shared defaults
├── scripts/              Installation, rendering, audit, and maintenance tools
├── browse/               Optional browser daemon source
├── tests/                Hook, config, installer, and skill regression checks
├── docs/                 Setup, inventory, and audit references
├── skills-manifest.json  Skill bindings, provenance, and package hashes
└── install.sh            Installer
```

Identical shared packages have one source under `shared/skills` and relative aliases in the tool directories. Tool-specific adaptations remain separate. The manifest records binding names, frontmatter names, origins, notices, and full package hashes.

## Public defaults and private state

| Versioned source | Local configuration or state |
| :--- | :--- |
| `claude/settings.json` | `~/.claude/settings.local.json` |
| `claude/.env.example` | `~/.claude/.env` |
| `claude/mcp.example.json` | Your configured MCP integrations and credentials |
| `claude/user/*.md` blank templates | `~/.claude/USER/` personal context |
| `codex/config.base.toml` | `${XDG_CONFIG_HOME:-$HOME/.config}/codex/config.local.toml` |
| Shared skills and rules | Assistant authentication, sessions, memory, and caches |

Claude reads its native local settings overlay. Codex uses a generated config built from the shared base, style profiles, and private TOML overlay:

```sh
./scripts/render-codex-config.sh
```

Edit the base or private overlay, then render again. The renderer merges TOML by key, validates before replacing the output, and preserves existing plugin/marketplace and unrelated native state. An invalid overlay leaves the previous valid config in place.

The supplied Codex base records model, reasoning, approval, and sandbox preferences explicitly. Its current approval policy is `never` and sandbox mode is `danger-full-access`; these are inspectable preferences in [the base config](../codex/config.base.toml). Put personal choices and project trust entries in the private overlay. Trust examples are commented until configured.

## Agents and workflows

Both assistants have eight roles:

| Role | Responsibility |
| :--- | :--- |
| `team-lead` | Coordinates work and phase boundaries |
| `researcher` | Explores the codebase without editing |
| `planner` | Designs the implementation and verification plan |
| `coder` | Implements changes and runs relevant checks |
| `reviewer` | Reviews plans and code |
| `review-fix` | Reviews and patches issues within its policy |
| `phase-implementer` | Completes a bounded implementation task |
| `ball-buster` | Challenges code and architectural decisions |

Claude workflows are slash commands:

```text
/workflow-feature add a settings page
/workflow-bugfix investigate a failed save
/workflow-review-only review the authentication module
```

Codex workflows are installed at `~/.codex/workflows`. For example:

```sh
codex "Follow $HOME/.codex/workflows/feature.md to implement a settings page"
codex '$config-editor audit the current configuration'
```

Keep the single quotes around the second example so the shell passes the skill name literally. See [Claude commands](../claude/commands), [Codex workflows](../codex/workflows), and the [skill catalog](skills.md) for the complete inventory.

## Hooks and status

Claude hook definitions live in `claude/settings.json`; Codex hook definitions live in `codex/hooks.json`. Their managed script paths resolve through the installed repository alias.

The Bash guards inspect executable command words for recognized risky operations. Their supported approval behavior differs by assistant. They do not resolve arbitrary scripts or dynamically constructed commands. The formatter hook uses installed tools and does not download formatters.

Claude's status line shows model, response style, execution/safety mode, context, cost, and timing. Codex uses its native status line and the installed `concise`, `technical`, and `review` instruction profiles.

Sound notifications use an optional external `ai-notify` helper. The `cx`, `cx-fast`, and `cx-deep` terminal launchers are also external integrations; this repository does not install them. They are not required for the core setup.

The [MCP example](../claude/mcp.example.json) describes Playwright, Context7, and shadcn integrations. Configure those tools and any credentials separately from the versioned defaults.

## Maintain and verify

```sh
python3 scripts/skills-inventory.py --check
python3 scripts/skills-inventory.py --installed
python3 -B scripts/verify-avoid-ai-writing.py
python3 -B -m unittest discover -s tests -v
```

The inventory check validates aliases, required resources, provenance notices, and full package hashes. `--installed` reports differences without changing local skills. After an intentional skill update, review the package and its notices, then run `python3 scripts/skills-inventory.py --refresh` to refresh the manifest and generated catalog.

Re-run `./install.sh` to refresh installed links. Existing backups live under `${XDG_CONFIG_HOME:-$HOME/.config}/ai-config/backups/`; private overlays and personal context stay outside the shared source.

Original local context and session notes are personal state. Keep them outside Git. The [privacy review](privacy.md) records the source and history audit scope.
