Audit and improve my AI assistant configuration and instruction docs.

Scope: $ARGUMENTS (blank = current repo + active Claude/Codex config; include `apply` to patch files after the audit)

1. DISCOVER THE REAL ACTIVE CONFIG
   - Resolve symlinks before editing; patch the real source file, not only the linked path.
   - Read the governing docs that exist in scope: `AGENTS.md`, `CLAUDE.md`, `TOOLS.md`, relevant `README*`, and any config or policy docs that define agent behavior.
   - Read the actual tool config files when present: `~/.claude/settings.json`, `~/.claude/settings.local.json`, `~/.claude/.mcp.json`, `~/.codex/config.toml`.
   - Inventory actual active items from the filesystem for both Claude and Codex: agents, slash commands, workflows, skills, MCP servers, rules, hooks, and shared policy docs.
   - Compare Claude and Codex surfaces for compatibility drift: missing equivalents, naming mismatches, behavior mismatches, and features that exist in one tool but not the other.

2. AUDIT THE CONFIG
   - Rewrite vague policy text into RFC 2119 language (`MUST`, `SHOULD`, `MAY`) while preserving intent.
   - Flag ambiguity, duplication, contradictions, stale references, and sections that are too long or too detailed for a professional operating guide.
   - Report raw counts for agents, commands, workflows, skills, MCP servers, and other always-on config surfaces.
   - Check for likely overload using these warning heuristics:
     - more than 8 agents
     - more than 40 slash commands
     - more than 6 active MCP servers
     - more than 20 active skills
     - overlapping tools or skills that perform the same job
   - Treat those heuristics as warnings, not automatic failures; if the count is justified, say so explicitly.
   - Identify what can be merged, archived, deleted, or downgraded from always-on to optional.

3. REPORT
   Produce:

   ## AI Config Audit

   ### Active Inventory
   - counts and notable items

   ### Overload Assessment
   - what is within bounds
   - what is excessive or redundant
   - what is justified despite the count

   ### Claude/Codex Compatibility Drift
   - what is identical
   - what is missing on one side
   - what should be normalized for both tools

   ### RFC 2119 Rewrite Suggestions
   - exact cleaned wording for ambiguous or weak rules

   ### Length and Professionalism Review
   - where docs are too long
   - what to trim, merge, or move

   ### Recommended Changes (prioritized)
   1. highest-value change
   2. next change
   3. optional cleanup

4. APPLY MODE
   - If the arguments include `apply`, patch the files directly after the audit.
   - Prefer deleting duplication over adding more prose.
   - Keep rewritten policy text concise, enforceable, and testable.
   - Preserve credentials, tokens, and personal secrets; do not rewrite or expose them.

Rules:

- Use actual filesystem state and actual config contents; do not guess.
- Keep recommendations concrete: name the file, the section, and the exact reason.
- When editing, preserve the user's intent and information hierarchy.
- If a rule is not verifiable, rewrite it into a verifiable form or flag it as unverifiable.
- Treat Claude/Codex parity as a first-class check; if one tool has a capability that should exist in the other, flag it explicitly.
