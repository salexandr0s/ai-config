# AGENTS.md snippet (copy/paste)

## UI/UX Design System Contract

When generating UI/UX, components, layouts, or styles:

- You MUST follow:
  - uiux-contract/agent_contract.yaml
  - uiux-contract/design_tokens.json
  - uiux-contract/quality_gates.yaml
  - uiux-contract/components/\*.yaml

Rules:

- Use tokens only (no arbitrary hex values / px spacing).
- Define all interactive states (default/hover/active/focus-visible/disabled/loading).
- Ensure responsiveness (360px → 1440px) and accessibility (keyboard + focus + contrast).
- If a needed value/pattern is missing, extend the contract first.
