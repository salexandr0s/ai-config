# Assistant UX Contract

This repo standardizes cross-tool interaction modes without forcing identical implementation details.

## Canonical Defaults

- Canonical root spelling: `~/GitHub`
- Lowercase `~/github` may still resolve on case-insensitive filesystems, but configs and scripts should target `~/GitHub`
- Shared default execution mode: `normal`
- Shared default response style: `concise`
- Shared completion notification path: `~/GitHub/terminal-config/bin/ai-notify`
- Assistant status surfaces should prefer AI telemetry over cwd/git metadata

## Execution Mode Mapping

| Shared Mode | Claude | Codex | Intent |
| --- | --- | --- | --- |
| `fast` | `--effort low` | `model_reasoning_effort = "low"` | Lowest-friction implementation and routine edits |
| `normal` | `--effort high` | `model_reasoning_effort = "xhigh"` | Default working mode |
| `deep` | `--effort max` | `model_reasoning_effort = "xhigh"` | Heavier planning, debugging, and review |

## Style Mapping

| Claude | Codex | Intent |
| --- | --- | --- |
| `House Concise` | `concise` | Minimal, action-first responses |
| `House Technical` | `technical` | Precise, implementation-oriented detail |
| `House Review` | `review` | Finding-first review responses |

## Notification Policy

- Shared default notification behavior: smart notify with cooldown, not always-on sound spam
- Notifications SHOULD use the shared `ai-notify` helper so local overrides remain tool-agnostic
- Claude and Codex SHOULD pass through `mode` and event context when practical so notifier behavior can evolve without per-tool rewrites

## Ownership

- `ai-config`: assistant-native settings, hooks, status lines, profiles, shared instructions
- `terminal-config`: launchers, notifiers, shell wiring, root-path normalization
- `ghostty-config`: terminal emulator appearance and shell integration
