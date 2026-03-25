---
name: config-editor
description: "Audit and improve AI assistant configuration and instruction docs. Use when the user wants to review or edit AGENTS.md, CLAUDE.md, TOOLS.md, Claude/Codex config, skill counts, MCP counts, parity drift, or RFC 2119 wording. Triggers on \"config editor\", \"audit my AI config\", \"check Claude/Codex parity\", \"rewrite this in RFC 2119\", \"too many skills\", \"too many MCPs\", \"clean up assistant config\"."
---

# AI Config Editor

Audit the real active AI configuration and improve it without guessing.

## Process

1. Resolve symlinks and identify the real source files before editing.
2. Read governing docs in scope:
   - `AGENTS.md`
   - `CLAUDE.md`
   - `TOOLS.md`
   - relevant `README*`
   - other policy or config docs that define agent behavior
3. Read live config files when present:
   - `~/.claude/settings.json`
   - `~/.claude/settings.local.json`
   - `~/.claude/.mcp.json`
   - `~/.codex/config.toml`
4. Inventory actual active Claude and Codex surfaces:
   - agents
   - slash commands
   - workflows
   - skills
   - MCP servers
   - rules
   - hooks
   - shared policy docs
5. Compare Claude and Codex for parity drift:
   - missing equivalents
   - naming mismatches
   - behavior mismatches
   - one-sided capabilities that should likely exist on both sides
6. Audit wording and structure:
   - rewrite weak policy text into RFC 2119 form (`MUST`, `SHOULD`, `MAY`)
   - flag ambiguity, duplication, contradictions, stale references, and sections that are too long for a professional operating guide
7. Assess likely overload with these warning heuristics:
   - more than 8 agents
   - more than 40 slash commands
   - more than 6 active MCP servers
   - more than 20 active skills
   - overlapping tools or skills that serve the same purpose
8. Treat heuristics as warnings, not automatic failures; explicitly justify any high count that is reasonable.
9. Recommend what to merge, archive, remove, or downgrade from always-on to optional.

## Rules

- Use actual filesystem state and actual config contents; do not guess.
- Treat Claude/Codex parity as a first-class check.
- Keep recommendations concrete: name the file, the section, and the reason.
- When editing, preserve the user's intent and information hierarchy.
- Prefer deleting duplication over adding more prose.
- Keep rewritten policy text concise, enforceable, and testable.
- If a rule is not verifiable, rewrite it into a verifiable form or flag it as unverifiable.
- Preserve secrets, tokens, and personal credentials; do not expose or normalize them unless the user explicitly asks.

## Output Format

1. **AI Config Audit**
2. **Active Inventory** — counts and notable active items
3. **Overload Assessment** — what is within bounds, what is excessive, what is redundant
4. **Claude/Codex Compatibility Drift** — what is identical, what is missing on one side, what should be normalized
5. **RFC 2119 Rewrite Suggestions** — exact cleaned wording
6. **Length and Professionalism Review** — what to trim, merge, or move
7. **Recommended Changes** — prioritized list with target files

If the user asks to apply changes, patch the real source files after the audit.
