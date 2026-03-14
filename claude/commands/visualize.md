---
description: "Generate a visual HTML page — diagrams, plans, slides, diff reviews, plan reviews, or project recaps. Usage: /visualize <type> [args]"
---

Load the visual-explainer skill, then generate the requested visualization type.

**Type:** `$1` (required — one of: `diagram`, `plan`, `slides`, `diff`, `plan-review`, `recap`)
**Arguments:** `$2` onward are passed as context to the visualization.

Follow the visual-explainer skill workflow. Read the reference template, CSS patterns, and mermaid theming references before generating. Pick a distinctive aesthetic that fits the content — vary fonts, palette, and layout style from previous visualizations.

If `surf` CLI is available (`which surf`), consider generating AI illustrations via `surf gemini --generate-image` when an image would genuinely enhance the page. Embed as base64 data URI. See css-patterns.md "Generated Images" for container styles. Skip images when the topic is purely structural or data-driven.

Write all output to `~/.agent/diagrams/` and open the result in the browser.

---

## Type: `diagram`

Generate a beautiful standalone HTML diagram for the given topic.

Pick a distinctive aesthetic that fits the content. Write to `~/.agent/diagrams/` with a descriptive filename and open in browser.

---

## Type: `plan`

Generate a comprehensive visual implementation plan as a self-contained HTML page. Use an editorial or blueprint aesthetic.

**Data gathering phase:**

1. Parse the feature request — extract core problem, desired behavior, constraints, scope boundaries.
2. Read the relevant codebase — files to modify, existing patterns, related functionality, types/interfaces/APIs.
3. Understand extension points — hooks, events, plugins, config, public APIs, test patterns.
4. Check for prior art — similar features, related issues, reusable code.

**Design phase:**

1. State design — new/affected state variables, state machine if multi-modal behavior.
2. API design — commands, functions, endpoints, signatures, error cases.
3. Integration design — interaction with existing functionality, hooks, events.
4. Edge cases — concurrent operations, error conditions, boundary values, user mistakes.

**Verification checkpoint** — before generating HTML, produce a structured fact sheet:

- Every state variable (new and modified) with type and purpose
- Every function/command/API with signature
- Every file that needs modification with specific changes
- Every edge case with expected behavior
- Every assumption about the codebase (verify each; mark uncertain ones)

**Diagram structure:** Header (feature name, description, scope) → The Problem (before/after comparison panels) → State Machine (Mermaid flowchart) → State Variables (card grid) → Modified Functions (file path + code snippet + explanation) → Commands/API (table) → Edge Cases (table) → Test Requirements (grouped by unit/integration/edge) → File References → Implementation Notes (backward compat gold, warnings rose, performance amber).

**Visual hierarchy:** Sections 1-3 dominate on load (hero depth). Sections 4-6 are core details (elevated). Sections 7-10 are reference (flat/recessed, compact).

Code blocks: always use `white-space: pre-wrap` and `word-break: break-word`. Overflow prevention: `min-width: 0` on grid/flex children, `overflow-wrap: break-word` on text containers, never `display: flex` on `<li>` for markers.

---

## Type: `slides`

Generate a stunning magazine-quality slide deck as a self-contained HTML page.

Read the reference template at `./templates/slide-deck.html` and slide patterns at `./references/slide-patterns.md`.

**Aesthetic:** Pick from 4 slide presets (Midnight Editorial, Warm Signal, Terminal Mono, Swiss Clean) or riff on existing aesthetic directions. Commit to one direction throughout.

**Narrative structure:** Compose a story arc, not a list. Start with impact (title), build context (overview), deep dive (content, diagrams, data), resolve (summary/next steps). Plan slide sequence and assign compositions before writing HTML.

**Visual richness:** Visual-first, text-second. Add SVG accents, inline sparklines, mini-charts, small Mermaid diagrams where they make the story compelling.

**Compositional variety:** Consecutive slides must vary spatial approach. Alternate centered, left-heavy, right-heavy, split, edge-aligned, full-bleed. Three centered slides in a row means push one off-axis.

---

## Type: `diff`

Generate a visual HTML diff review — before/after architecture comparison with code review analysis. Use a GitHub-diff-inspired aesthetic with red/green before/after panels.

**Scope detection** from arguments:

- Branch name: working tree vs that branch
- Commit hash: `git show <hash>`
- `HEAD`: uncommitted changes (`git diff` + `git diff --staged`)
- PR number (`#42`): `gh pr diff 42`
- Range (`abc..def`): diff between two commits
- No argument: default to `main`

**Data gathering:** Run `git diff --stat`, `git diff --name-status`, line counts, grep for new public API surface, feature inventory, read all changed files in full, check CHANGELOG.md and docs for needed updates, reconstruct decision rationale from conversation/progress docs/commit messages.

**Verification checkpoint** — fact sheet of every claim: quantitative figures, function/type/module names, behavior descriptions. Cite sources. Mark uncertain items.

**Diagram structure:** Executive summary (hero — the _intuition_ behind changes) → KPI dashboard (lines/files/modules/tests + housekeeping indicators) → Module architecture (Mermaid dependency graph with zoom) → Major feature comparisons (side-by-side before/after) → Flow diagrams (Mermaid for new lifecycles) → File map (color-coded tree) → Test coverage (before/after) → Code review (Good/Bad/Ugly/Questions with colored cards) → Decision log (cards with confidence levels: green=sourced, blue=inferred, amber=not recoverable) → Re-entry context (invariants, coupling, gotchas, follow-ups).

**Visual hierarchy:** Sections 1-3 hero depth. Sections 6+ lighter/collapsible. Diff color language: red=removed, green=added, yellow=modified, blue=neutral.

---

## Type: `plan-review`

Generate a visual HTML plan review — current codebase state vs. proposed implementation plan. Use a blueprint/editorial aesthetic.

**Inputs:** Plan file path as first argument, codebase path as optional second (defaults to cwd).

**Data gathering:**

1. Read plan file — extract problem, proposed changes, rejected alternatives, scope boundaries.
2. Read every file the plan references + files that import/depend on them.
3. Map blast radius — imports, tests, config, schemas, public API surface.
4. Cross-reference plan vs. code — verify files/functions/types exist, behavior matches plan's description, check implicit assumptions.

**Verification checkpoint** — fact sheet citing plan sections and file:line sources.

**Diagram structure:** Plan summary (hero — intuition + scope) → Impact dashboard (files modify/create/delete, completeness indicators) → Current architecture (Mermaid, zoom) → Planned architecture (same node names/layout as current, highlight new/removed/changed) → Change-by-change breakdown (side-by-side current vs. planned with rationale, flag discrepancies and missing rationale) → Dependency & ripple analysis (callers/importers, color: green=covered, amber=likely affected, red=missed) → Risk assessment (edge cases, assumptions, ordering, rollback, cognitive complexity with severity + mitigation) → Plan review (Good/Bad/Ugly/Questions cards) → Understanding gaps (rationale gap counts, complexity flags, recommendations).

**Visual hierarchy:** Sections 1-4 hero/elevated. Sections 6+ lighter/collapsible. Color language: blue=current, green/purple=planned, amber=concerns, red=gaps.

---

## Type: `recap`

Generate a visual HTML project recap — rebuild mental model of a project's current state, recent decisions, and cognitive debt hotspots. Use a warm editorial or paper/ink aesthetic.

**Time window** from arguments:

- Shorthand (`2w`, `30d`, `3m`): parse to git `--since` format
- No time pattern: default to `2w`

**Data gathering:**

1. Project identity — README, CHANGELOG, package manifest, top-level structure.
2. Recent activity — `git log --oneline --since`, `git log --stat --since`, `git shortlog -sn --since`, most active areas.
3. Current state — uncommitted changes, stale branches, TODOs/FIXMEs, progress docs.
4. Decision context — commit messages, conversation history, plan docs, RFCs, ADRs.
5. Architecture scan — key source files, entry points, public API, frequently changed files.

**Verification checkpoint** — fact sheet citing git command output and file:line sources.

**Diagram structure:** Project identity (current-state summary, not README blurb) → Architecture snapshot (Mermaid, zoom, hero depth — the visual anchor) → Recent activity (human-readable narrative grouped by theme with timeline) → Decision log (what/why/alternatives from time window) → State of things (KPI cards: working/in-progress/broken/blocked with trend indicators) → Mental model essentials (invariants, non-obvious coupling, gotchas, naming conventions) → Cognitive debt hotspots (amber cards with severity: undocumented changes, untested modules, overlapping edits, poorly understood files, each with concrete suggestion) → Next steps (inferred from momentum + TODOs + progress docs).

Overflow prevention on grid/side-by-side sections. Responsive section navigation. Color language: muted blues/greens for architecture, amber for cognitive debt, green/blue/amber/red for status.

$@
