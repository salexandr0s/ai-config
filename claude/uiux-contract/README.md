# UI/UX Contract Pack (Apple Minimal)

This folder contains **machine/agent-readable** contracts + tokens that define how new UI should be designed.

## What an agent must do

1. Load and follow:
   - `agent_contract.yaml` (high-level rules)
   - `design_tokens.json` (all visual values)
   - `quality_gates.yaml` (self-checks before shipping)
   - `components/*.yaml` (component anatomy, sizing, states)

2. Never hardcode arbitrary values for:
   - colors, spacing, radii, shadows, typography, motion
     Use `design_tokens.json` tokens.

3. When in doubt:
   - prefer clarity, minimalism, and consistency
   - follow component contracts

## How to reference from AGENTS.md

Add something like:

```md
## UI/UX Design System Contract

All UI work MUST follow the contract files below:

- uiux-contract/agent_contract.yaml
- uiux-contract/design_tokens.json
- uiux-contract/quality_gates.yaml
- uiux-contract/components/\*.yaml

If a design decision is not covered, extend tokens/contracts first, then implement.
```

## Notes

- Semantic tokens support `light` and `dark` modes.
- Component contracts use token references like `{space.4}` and `{color.semantic.(mode).fg}`.
