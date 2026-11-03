<div align="center">

# ai-config

### Shared skills and workflows for Claude Code and Codex.

A versioned setup for coding assistants: matching agent roles, reusable skills,<br />
workflow prompts, hooks, and design standards. Personal state stays local.

[**Get started**](#install) · [Skill catalog](docs/skills.md) · [Configuration guide](docs/configuration.md)

**78** bundled skills &nbsp; / &nbsp; **8** agent roles &nbsp; / &nbsp; **2** assistants

</div>

<br />

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/overview-dark.svg" />
  <source media="(prefers-color-scheme: light)" srcset="docs/images/overview-light.svg" />
  <img src="docs/images/overview-light.svg" alt="Shared skills and standards feed Claude Code and Codex; private overrides, credentials, and memory stay local." width="840" />
</picture>

## What it provides

| Part | Purpose |
| :--- | :--- |
| **Skills** | Design, writing, security, debugging, Apple platforms, deployment, and project maintenance |
| **Agent roles** | A matching eight-role roster for planning, implementation, review, and coordination |
| **Workflows** | Claude slash commands and installed Codex prompt templates for features, fixes, and reviews |
| **Configuration** | Shared defaults, response styles, hook wiring, and private local overlays |
| **Design standards** | Typed visual tokens, component specifications, and UI quality checks |
| **Installer** | Relocatable links, backups, config validation, and optional browser/LaunchAgent setup |

The [skill catalog](docs/skills.md) lists every binding, its assistant availability, source, and attribution. There are 46 Claude bindings and 74 Codex bindings; identical shared packages have one canonical source. Tool-specific adaptations remain separate.

## Install

macOS-first. Requires **Bash, Git, and Python 3.11+**. Install Claude Code, Codex, or both separately. Node.js 18+ runs the bundled writing tools; the configured shadcn MCP integration also needs a compatible Node/npm installation on PATH. Bun is optional.

The supplied Codex base uses `danger-full-access` and approval policy `never`. Review [runtime preferences](docs/configuration.md#public-defaults-and-private-state) before installing, and keep personal overrides in the private local configuration.

```sh
git clone https://github.com/salexandr0s/ai-config.git
cd ai-config
./install.sh
```

Managed tool-link replacements are backed up. Codex configuration is merged, validated, and regenerated; private overlays and personal context are preserved. The default setup links configuration, skills, commands, and workflows without building the browser daemon or starting a background job.

```sh
./install.sh --with-browse       # Optional: build the browser daemon with Bun
./install.sh --with-launchagent  # Optional: weekly memory rotation on macOS
```

To install workspace instructions somewhere other than an existing `~/GitHub`, use `./install.sh --workspace "$HOME/Projects"`. See [installation and configuration](docs/configuration.md) for file destinations, local overrides, and runtime preferences.

## Use it

In Claude Code:

```text
/workflow-feature add a settings page
/workflow-bugfix investigate a failed save
/workflow-review-only review the authentication module
```

In Codex CLI:

```sh
codex '$config-editor audit the current configuration'
codex "Follow $HOME/.codex/workflows/feature.md to implement a settings page"
```

Skill availability differs by assistant. The catalog includes writing with [avoid-ai-writing](shared/skills/avoid-ai-writing), product demonstrations with [Stageshow](shared/skills/stageshow), security review with [deepsec](shared/skills/deepsec), and the complete platform/design/deployment inventory. The locally installed `aside-browser` skill is listed as external because its upstream bundle has no redistribution license; it is preserved locally and not vendored here.

## How it's organized

| Directory | Owns |
| :--- | :--- |
| [`shared/`](shared) | Canonical shared skills, workspace instructions, and assistant UX conventions |
| [`claude/`](claude) | Claude agents, commands, skill bindings, settings, resources, and UI contracts |
| [`codex/`](codex) | Codex agents, skill bindings, workflows, rules, styles, and base TOML |
| [`scripts/`](scripts) | Installation helpers, config rendering, inventory checks, and maintenance tools |
| [`browse/`](browse) | Optional browser daemon source |
| [`tests/`](tests) | Regression checks for hooks, configuration, installation, and skill packaging |

[skills-manifest.json](skills-manifest.json) records skill provenance and package hashes. The [generated catalog](docs/skills.md) is checked against it, including relative aliases and required resources.

## Private configuration

Shared defaults belong in this repository. Credentials, local settings, trusted project paths, personal identity files, memory, sessions, caches, and session journals stay outside Git.

| Public source | Private local counterpart |
| :--- | :--- |
| `claude/settings.json` | `~/.claude/settings.local.json` |
| `codex/config.base.toml` | `~/.config/codex/config.local.toml` |
| Blank `claude/user/` templates | `~/.claude/USER/` personal context |

Codex configuration is merged and validated before replacing the live file. Invalid local TOML leaves the previous config intact. See the [privacy review](docs/privacy.md) for source boundaries and historical cleanup scope.

## Verify and maintain

```sh
python3 scripts/skills-inventory.py --check
python3 scripts/skills-inventory.py --installed
python3 -B scripts/verify-avoid-ai-writing.py
python3 -B -m unittest discover -s tests -v
```

`--installed` reports differences without replacing local skills. After an intentional skill change, review the source and notices, then run `python3 scripts/skills-inventory.py --refresh`. Re-run the installer to refresh links; private overlays are retained.

## Documentation

- [Installation, local overlays, hooks, agents, and workflows](docs/configuration.md)
- [Complete skill catalog and external integrations](docs/skills.md)
- [Privacy boundary and history review](docs/privacy.md)
- [UI/UX design contract](claude/uiux-contract/README.md)
- [Shared writing skill and its verification tools](shared/skills/avoid-ai-writing/README.md)

Third-party skills retain their own licenses and notices, recorded in their packages and the manifest. This repository does not apply one blanket license to those sources.
