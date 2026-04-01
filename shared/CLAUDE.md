# Workspace Standards & Agent Team Workflow

Dev standards and agent coordination for all projects in `~/GitHub`.
Key words: **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, **MAY** per RFC 2119.

---

## Hard Rules

1. Agents **MUST NOT** perform mass automated renames — use small batches with verification between each
2. Agents **MUST NOT** run destructive git operations without user confirmation — verify branch state first
3. Agents **MUST NOT** add blanket type suppressions — each MUST have context-specific justification
4. Agents **MUST** run checks frequently — MUST NOT accumulate 50+ changes before verifying
5. Agents **MUST** respect project-level `CLAUDE.md` — project rules override workspace rules on conflict
6. Agents **MUST NOT** weaken rules to pass checks — fix the code, not the rules
7. Agents **MUST** verify their own work — run verification commands before marking complete
8. Agents **SHOULD** log repeatable errors to `~/.claude/MEMORY/LEARNINGS/what-fails.md`
9. Before any structural refactor on a file over 300 LOC, agents **MUST** first remove dead props, unused imports/exports, unreachable code, and debug logs; that cleanup **MUST** be isolated from the refactor and, when commits are in scope, **MUST** be committed separately before the refactor
10. Agents **MUST NOT** use "simplest approach" or "stay in scope" as a reason to preserve flawed architecture, duplicated state, or inconsistent patterns — propose the structural fix a senior reviewer would expect and get approval if scope expands
11. Agents **MUST** use a dual-mode quality posture: straightforward localized tasks **SHOULD** stay within approved scope, but refactors, architecture work, and AI-config or policy work **MUST** be held to senior-review quality and **MUST NOT** preserve reviewer-visible structural issues for brevity

---

## Session Protocol

### Start

1. Agent **MUST** identify current project from working directory
2. Agent **SHOULD** read recent session logs in `~/.claude/MEMORY/SESSIONS/` for cross-tool context
3. Agent **MUST** check for project-level `CLAUDE.md` — it overrides this file on conflict
4. Agent **SHOULD** detect stack from `package.json` / `pyproject.toml` / `Cargo.toml`
5. Agent **SHOULD** read `~/.claude/USER/MISSION.md` and `~/.claude/USER/GOALS.md` for user context

### End (when files were modified)

1. Agent **MUST** run `/handoff` — this writes SESSION_HANDOFF.md (session-capture hook handles journaling automatically)
2. Agent **MUST** note unfinished work in the handoff document
3. Agent **SHOULD** extract any explicit user feedback and append to `~/.claude/MEMORY/SIGNALS/ratings.jsonl`

### MEMORY System

All agents share `~/.claude/MEMORY/`: `SESSIONS/` (session summaries), `SIGNALS/` (user feedback), `LEARNINGS/` (patterns), `STATE/` (system/event logs), and `RESEARCH/` (knowledge artifacts). Run `~/.claude/MEMORY/scripts/rotate.sh` periodically for maintenance.

---

## Dev Stack (Defaults for New Projects)

New projects **SHOULD** use this stack unless requirements dictate otherwise:

- Language: **TypeScript** (strict mode)
- Web/API/Desktop: **Next.js** (app router), **Fastify**, **Electron + Vite**
- Styling/UI: **TailwindCSS** + **Radix UI**
- Validation/Data/Auth: **Zod**, **Prisma** or **Drizzle**, **Supabase**
- Testing/Linting/Monorepo: **Vitest** + **Playwright**, **ESLint 9** + **Prettier**, **Turbo** + npm workspaces
- Python: **Python 3.10+** with **Ruff** (Clawdbot skills only)

---

## Coding Style

### TypeScript

- All projects **MUST** use strict mode — `"strict": true` in tsconfig
- Agents **MUST NOT** use `any` — use `unknown` + type guards at boundaries
- API boundaries **MUST** use Zod — parse, don't assume shapes
- Agents **SHOULD** prefer `interface` for object shapes, `type` for unions/intersections/utility types
- Agents **SHOULD** use named exports over default exports — easier to refactor and grep

### Naming

- Files **MUST** use `kebab-case` filenames (e.g., `user-profile.ts`, `user-profile.tsx`)
- Components **MUST** use `PascalCase` in code, `kebab-case` file (e.g., `user-card.tsx` → `UserCard`)
- Hooks **MUST** use `use-` prefix file (e.g., `use-auth.ts` → `useAuth`)
- Types **SHOULD** be colocated in same file, or `types.ts` if shared

### Project Structure

```
app/                  # Next.js app router pages
  (auth)/             # Route groups
  api/                # API routes
components/ui/        # Shared UI primitives
hooks/                # Shared React hooks
lib/                  # Utilities, clients, DB
types/                # Shared TypeScript types
public/               # Static assets
tests/                # E2E tests (Playwright)
```

Monorepos **SHOULD** use: `apps/{web,api,desktop}` + `packages/{shared,ui}`

---

## Git Conventions

### Branches

`main` (production) · `dev` (integration, optional) · `feat/slug` · `fix/slug` · `chore/slug`

### Commit Messages

Format **MUST** be: `type(scope): short description`
Types: `feat` · `fix` · `chore` · `refactor` · `test` · `docs` · `style` · `perf`

### Rules

- Agents **MUST** commit logical units, not "save progress" dumps
- Agents **MUST NOT** commit `.env`, credentials, or secrets
- Agents **MUST** run lint + type-check before committing
- Commits **SHOULD** be small and reviewable

---

## Tools & Services

### Secrets — claudecodex Vault

Keys live in macOS Keychain (`claudecodex.keychain-db`) and auto-load via `.zprofile`; use `~/.claude/claudecodex-vault.sh [set|get|list|delete|export] <key> <value>`. Per-project keys **MUST** go in `.env` files (never committed).

### MCP Plugins

Installed MCP plugins: **Playwright** (browser automation & E2E), **Context7** (up-to-date library docs), and **shadcn** (component registry browse/install). Additional MCP servers can be configured per-project in `.mcp.json`.

### OpenClaw Gateway

Local agent orchestration on `127.0.0.1:18789`: Brave Search, QMD Memory, TTS (OpenAI Shimmer), and agent-to-agent messaging.

### QMD — Knowledge Search (NOT Code Search)

`qmd` is a hybrid markdown search tool (BM25 + vector + reranking); binary: `qmd`; expected major version: `2.x`.
Agents **MUST NOT** use qmd for code search — use Grep/Glob/LSP instead.
Agents **SHOULD** use qmd for knowledge recall and **SHOULD** query relevant context before planning a task (e.g., `qmd query "auth decisions"`).
Collections: `memory` (`~/openclaw/memory`), `knowledge-graph` (`~/openclaw/life/areas`), and `workspace` (`~/openclaw`, `*.md` only).

### Dev Scripts

Use `dev-verify` (full quality check), `dev-format` (format files), and `dev-status` (git + quality snapshot). These auto-detect project type (Rust/Node/Python), and agents **SHOULD** prefer them over raw `npm run lint`.

### Browse Daemon

Persistent headless Chromium for web interaction and QA testing. Binary: `browse` (compile from `browse/` with Bun); manage with `browse-ctl {ensure|start|stop|status}`; state lives at `~/.browse/state.json`.
Use `/browse` for persistent browser interaction and `/qa --browser <url>` for browser-based QA; use MCP Playwright for one-off automation.

---

## Verification

Agents **MUST** check for a `## Verification` section in the project's `CLAUDE.md` first. If none exists:

```bash
dev-verify              # Auto-detects project type, runs lint + typecheck + tests
dev-verify --quick      # Skip tests for rapid iteration
```

Agents **MUST** run `dev-verify --quick` after every 3–5 file changes. Agents **MUST** run full `dev-verify` before commits and before marking tasks complete.

For JS/TS projects, verification **MUST** include `npx tsc --noEmit` (or project equivalent) and, if ESLint is configured, `npx eslint . --quiet` (or project equivalent). Agents **MUST NOT** mark work complete until all reported errors are fixed. If no type-checker is configured, agents **MUST** state that explicitly.

If `dev-verify` cannot run because the repo has no detectable project type or no unified verify entrypoint, agents **MUST** run targeted validation that matches the touched files (for example: JSON parse, `tomllib` parse, `bash -n`, generated-config render smoke test) and **MUST** report that fallback explicitly.

## Bug Handling

- When an agent identifies a bug, the agent **MUST** report the suspected root cause, the proposed fix, and the agent's confidence in that fix.
- Confidence **SHOULD** be stated plainly (`high`, `medium`, or `low`) and **SHOULD** note any key assumptions or unknowns.
- A bug **MAY** be treated as simple only when the root cause is narrow, the fix is localized, and regression risk is low.
- For any bug that is not simple, the agent **SHOULD** create or identify a test that reproduces the bug before implementing the fix.
- If the agent does not add a reproducing test for a non-simple bug, the agent **MUST** explain why.
- For a simple bug, the agent **MAY** fix first and add or update regression coverage immediately after, but the agent **SHOULD** still add regression coverage when practical.

---

## Team Workflow

### When to Use Teams

- Teams **SHOULD** be used for: new features, multi-file changes, refactoring, architectural changes, bugs requiring investigation, anything touching 3+ files
- Teams **SHOULD NOT** be used for: single-line fixes, typos, config tweaks, pure research, or when user says "quick mode"
- Tasks touching more than 5 independent files **MUST** be split across parallel subagents with disjoint ownership; each subagent **SHOULD** own 5–8 files or one bounded subsystem. If safe parallelization is blocked by dependencies or tooling, the agent **MUST** state that explicitly

### Formation

Agents **MUST** use `TeamCreate` with agents from `~/.claude/agents/`:

| Role       | Agent        | When                                                       |
| ---------- | ------------ | ---------------------------------------------------------- |
| Lead       | `team-lead`  | Always — **MUST** include                                  |
| Researcher | `researcher` | **SHOULD** include when codebase exploration needed        |
| Planner    | `planner`    | **SHOULD** include for multi-file or architectural changes |
| Coder      | `coder`      | **MUST** include for all implementation                    |
| Reviewer   | `reviewer`   | **MUST** include for plan review and code review           |

### Phases

| #   | Phase       | Agent        | Gate                                     |
| --- | ----------- | ------------ | ---------------------------------------- |
| 1   | Understand  | `researcher` | Lead confirms understanding              |
| 2   | Plan        | `planner`    | —                                        |
| 3   | Review Plan | `reviewer`   | **MUST** get user approval before coding |
| 4   | Implement   | `coder`      | —                                        |
| 5   | Review Code | `reviewer`   | —                                        |
| 6   | Polish      | `coder`      | All items **MUST** be resolved           |

- Multi-file refactors **MUST NOT** be attempted in a single response; they **MUST** be split into explicit phases touching no more than 5 files per phase
- Each phase **MUST** end with verification and user approval before the next phase begins

### Communication

- Agents **MUST** use `SendMessage` for direct messages; `broadcast` **SHOULD** only be used for critical blockers
- Agents **MUST** announce phase transitions: `[Phase N: Name]`
- Agents **MUST** gate on user approval before implementation (Phase 3 → 4)
- All agents **MUST** use shared task list (`TaskCreate` / `TaskUpdate`)

### Subagent Prompt Requirements

When spawning a subagent via the `Agent` tool, the prompt **MUST** include:

1. **Project context** — project path, branch, stack (e.g., "Next.js app router + Supabase")
2. **Goal** — a clear, single objective with success criteria
3. **Relevant state** — files already changed, decisions already made, constraints
4. **Key file paths** — specific files the agent needs to read or modify
5. **What NOT to do** — any approaches already ruled out or boundaries to respect

Agents **MUST NOT** write one-line prompts like "fix the auth bug" or "add tests". Minimum prompt length is 4 sentences.

Background agents **MUST** be fully self-contained — they cannot reference "the above conversation" or "what we discussed".

### User Question Format

When asking the user a question, agents **SHOULD**:
1. **Re-ground:** State current project, branch, and task (1–2 sentences)
2. **Simplify:** Explain in plain English — no jargon, no raw function names
3. **Recommend:** "RECOMMENDATION: Choose X because [reason]"
4. **Options:** 2–4 concrete options with effort/impact notes

---

## Execution Discipline

### Autonomy Levels

| Level          | When                            | Behavior                                          |
| -------------- | ------------------------------- | ------------------------------------------------- |
| **Supervised** | Default / team workflow         | Plan requires user approval before implementation |
| **Bounded**    | Assigned to `phase-implementer` | Self-plans and executes within stated scope       |
| **Autonomous** | Assigned to `review-fix`        | Reviews and patches within fix policy             |

### Mechanical Safety Overrides

- Before every file edit, agents **MUST** re-read the file; after editing, agents **MUST** read it again to confirm the applied change. Agents **MUST NOT** make more than 3 edits to the same file without an intervening verification read
- After 10+ messages or any long pause, agents **MUST** re-read any file before editing it. Agents **MUST NOT** trust memory of file contents after compaction risk
- Each file read **MUST** stay under roughly 2,000 lines. Files over 500 LOC **MUST** be read in sequential chunks using offset/limit-style reads. Agents **MUST NOT** assume a single read captured the full file
- Agents **MUST** suspect truncation when a large tool result looks incomplete or unexpectedly short. When truncation is suspected, agents **MUST** rerun with narrower scope and state that truncation is suspected
- Grep **MUST NOT** be treated as semantic analysis. On any rename or signature change, agents **MUST** separately search direct calls, type references, string literals, dynamic imports, `require()` calls, re-exports, barrel files, and test mocks. Agents **MUST** assume grep missed something

### Phase Gates

- A plan **MUST** exist before implementation starts (even a 3-line plan counts)
- Verification **MUST** pass before marking any task complete
- Scope changes **MUST** be flagged to user — never silently expand
- If verification fails 3 times on the same issue → **STOP** and escalate

### Default Definition of Done

A task is done when ALL of:

1. Implementation matches the plan (or deviations are documented)
2. `dev-verify` passes, or when that is unavailable for the repo shape, equivalent targeted validation for touched file types passes and is reported explicitly
3. No new TODO/FIXME in changed files (unless explicitly deferred)
4. Changes committed with conventional message format
5. SESSION_HANDOFF.md written if work spans multiple sessions

### Completion Status Protocol

Agents **MUST** report task completion using one of:
- **DONE** — All steps completed, verification passes, evidence provided
- **DONE_WITH_CONCERNS** — Completed but with issues the user should know (list each)
- **BLOCKED** — Cannot proceed (state blocker, what was tried, recommendation)
- **NEEDS_CONTEXT** — Missing information required (state exactly what is needed)

3-strike escalation: if verification fails 3 times on the same issue, **STOP** and escalate.

### Continuity Protocol

To resume work: read `SESSION_HANDOFF.md` if it exists, run the resume commands from the handoff, check `git log`, then begin new work.
To end a session with incomplete work: run `/handoff` — it generates `SESSION_HANDOFF.md`, writes a journal entry, and syncs the memory index.

---

## UI/UX Design System (Apple Minimal)

Design system contract: `~/.claude/uiux-contract/`

**Before any UI work**, agents **MUST** read `design_tokens.json`, `quality_gates.yaml`, and the relevant `components/<name>.yaml` spec.
Agents **MUST NOT** use arbitrary visual values — all colors, spacing, radii, shadows, font sizes, and motion timings **MUST** use design tokens.
