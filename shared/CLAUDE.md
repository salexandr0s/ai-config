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
8. Agents **SHOULD** log repeatable errors to `~/GitHub/.memory/pitfalls/_active.md`

---

## Session Protocol

### Start

1. Agent **MUST** read `~/GitHub/.memory/_index.md` for available memory files
2. Agent **MUST** identify current project from working directory
3. Agent **MUST** read project memory (`~/GitHub/.memory/projects/<name>.md`) if it exists
4. If project file says "Pending first session documentation" → agent **MUST** run `~/GitHub/.memory/scripts/populate-project.sh <project-path>`
5. Agent **SHOULD** read last 2 journal entries for recent cross-tool context
6. Agent **MUST** check for project-level `CLAUDE.md` — it overrides this file on conflict
7. Agent **SHOULD** detect stack from `package.json` / `pyproject.toml` / `Cargo.toml`

### End (when files were modified)

1. Agent **MUST** run `/handoff` to generate SESSION_HANDOFF.md
2. Agent **MUST** run `~/GitHub/.memory/scripts/journal.sh "<tool>" "<project>" "<summary>"`
3. Agent **MUST** note unfinished work in the journal summary and the handoff document
4. Agent **SHOULD** update project/topic memory files if durable knowledge was gained

### Shared Memory

All agents (Claude Code, Codex, OpenClaw) share `~/GitHub/.memory/`:

| Directory    | Purpose                                   | Limit         |
| ------------ | ----------------------------------------- | ------------- |
| `topics/`    | Durable knowledge by topic                | 80 lines/file |
| `projects/`  | Per-project context                       | 60 lines/file |
| `decisions/` | ADR-lite records (immutable once created) | —             |
| `pitfalls/`  | Error patterns and fixes                  | 15 active     |
| `journal/`   | Chronological session notes (append-only) | —             |

Agents **SHOULD** run `~/GitHub/.memory/scripts/sync-stubs.sh` periodically for maintenance.

---

## Dev Stack (Defaults for New Projects)

New projects **SHOULD** use this stack unless requirements dictate otherwise:

| Layer         | Choice                                      | Why                                   |
| ------------- | ------------------------------------------- | ------------------------------------- |
| Language      | **TypeScript** (strict mode)                | Type safety, catches bugs early       |
| Web Framework | **Next.js** (app router)                    | Server components, file-based routing |
| API Framework | **Fastify**                                 | Faster than Express, schema-first     |
| Desktop       | **Electron + Vite**                         | Cross-platform, web tech reuse        |
| Styling       | **TailwindCSS**                             | Utility-first, no CSS files to manage |
| Components    | **Radix UI**                                | Accessible primitives, unstyled       |
| Validation    | **Zod**                                     | Runtime + TypeScript type inference   |
| Database      | **Prisma** (Postgres/SQLite) or **Drizzle** | Type-safe queries                     |
| Auth          | **Supabase**                                | Auth + DB + storage in one            |
| Testing       | **Vitest** (unit) + **Playwright** (E2E)    | Fast, modern, Vite-native             |
| Linting       | **ESLint 9** + **Prettier**                 | Flat config, consistent formatting    |
| Monorepo      | **Turbo** + npm workspaces                  | Fast builds, dependency management    |
| Python        | **Python 3.10+** with **Ruff**              | For Clawdbot skills only              |

---

## Coding Style

### TypeScript

- All projects **MUST** use strict mode — `"strict": true` in tsconfig
- Agents **MUST NOT** use `any` — use `unknown` + type guards at boundaries
- API boundaries **MUST** use Zod — parse, don't assume shapes
- Agents **SHOULD** prefer `interface` for object shapes, `type` for unions/intersections/utility types
- Agents **SHOULD** use named exports over default exports — easier to refactor and grep

### React

- Related files **SHOULD** be colocated — component + hook + types in same directory
- Reusable logic **SHOULD** be extracted into hooks — prefix with `use`
- Agents **SHOULD** prefer composition over prop drilling — use children and slots

### Naming

- Files **MUST** use `kebab-case.ts` (e.g., `user-profile.tsx`)
- Components **MUST** use `PascalCase` in code, `kebab-case` file (e.g., `user-card.tsx` → `UserCard`)
- Hooks **MUST** use `use-` prefix file (e.g., `use-auth.ts` → `useAuth`)
- Types **SHOULD** be colocated in same file, or `types.ts` if shared
- Constants **MUST** use `SCREAMING_SNAKE_CASE`
- Test files **MUST** use `*.test.ts` next to source

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

Keys in macOS Keychain (`claudecodex.keychain-db`), auto-loaded via `.zprofile`.
Usage: `~/.claude/claudecodex-vault.sh [set|get|list|delete|export] <key> <value>`
Per-project keys **MUST** go in `.env` files (never committed).

### MCP Plugins

| Plugin         | Purpose                     | Auth                           |
| -------------- | --------------------------- | ------------------------------ |
| **GitHub**     | PR/issue management         | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| **Playwright** | Browser automation & E2E    | Auto-managed                   |
| **Supabase**   | DB/auth management          | OAuth                          |
| **Stripe**     | Payment integration         | OAuth                          |
| **Firebase**   | Cloud services              | Firebase CLI                   |
| **Slack**      | Team messaging              | OAuth                          |
| **Linear**     | Issue tracking              | OAuth                          |
| **Greptile**   | AI code search across repos | `GREPTILE_API_KEY`             |
| **Context7**   | Up-to-date library docs     | None                           |

### OpenClaw Gateway

Local agent orchestration on `127.0.0.1:18789`:
Brave Search · QMD Memory · TTS (OpenAI Shimmer) · Agent-to-Agent messaging

### QMD — Knowledge Search (NOT Code Search)

`qmd` (v1.1.5) is a hybrid search tool (BM25 + vector + LLM reranking) for markdown files.
Binary: `/Users/savorgserver/.bun/bin/qmd`

Agents **MUST NOT** use qmd for code search — use Grep/Glob/LSP instead (faster, more precise).

Agents **SHOULD** use qmd for knowledge recall — past decisions, project context, documentation:

```bash
qmd search "query"                          # BM25 full-text (fast, deterministic)
qmd search "query" -c memory                # Search a specific collection
qmd vsearch "query"                         # Semantic vector search
qmd get "#docid"                            # Retrieve a specific document
```

Indexed collections: `memory` (`~/openclaw/memory`) · `knowledge-graph` (`~/openclaw/life/areas`) · `workspace` (`~/openclaw`, `*.md` only)

Agents **SHOULD** query relevant context before planning a task (e.g., `qmd search "auth decisions"`) to surface past decisions or domain knowledge.

### Dev Scripts

| Script       | Purpose                                       | Usage                                |
| ------------ | --------------------------------------------- | ------------------------------------ |
| `dev-verify` | Full quality check (lint + typecheck + tests) | `dev-verify` or `dev-verify --quick` |
| `dev-format` | Format all files for current project type     | `dev-format`                         |
| `dev-status` | Git state + quick quality snapshot            | `dev-status`                         |

These auto-detect project type (Rust/Node/Python). Agents **SHOULD** prefer these over raw `npm run lint`.

---

## Verification

Agents **MUST** check for a `## Verification` section in the project's `CLAUDE.md` first. If none exists:

```bash
dev-verify              # Auto-detects project type, runs lint + typecheck + tests
dev-verify --quick      # Skip tests for rapid iteration
```

Agents **MUST** run `dev-verify --quick` after every 3–5 file changes. Agents **MUST** run full `dev-verify` before commits and before marking tasks complete.

---

## Team Workflow

### When to Use Teams

- Teams **SHOULD** be used for: new features, multi-file changes, refactoring, architectural changes, bugs requiring investigation, anything touching 3+ files
- Teams **SHOULD NOT** be used for: single-line fixes, typos, config tweaks, pure research, or when user says "quick mode"

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

### Communication

- Agents **MUST** use `SendMessage` for direct messages; `broadcast` **SHOULD** only be used for critical blockers
- Agents **MUST** announce phase transitions: `[Phase N: Name]`
- Agents **MUST** gate on user approval before implementation (Phase 3 → 4)
- All agents **MUST** use shared task list (`TaskCreate` / `TaskUpdate`)

---

## Execution Discipline

### Autonomy Levels

| Level          | When                            | Behavior                                          |
| -------------- | ------------------------------- | ------------------------------------------------- |
| **Supervised** | Default / team workflow         | Plan requires user approval before implementation |
| **Bounded**    | Assigned to `phase-implementer` | Self-plans and executes within stated scope       |
| **Autonomous** | Assigned to `review-fix`        | Reviews and patches within fix policy             |

### Phase Gates

- A plan **MUST** exist before implementation starts (even 3 lines counts)
- Verification **MUST** pass before marking any task complete
- Scope changes **MUST** be flagged to user — never silently expand
- If verification fails 3 times on the same issue → **STOP** and escalate

### Default Definition of Done

A task is done when ALL of:

1. Implementation matches the plan (or deviations are documented)
2. `dev-verify` passes (lint + typecheck + tests)
3. No new TODO/FIXME in changed files (unless explicitly deferred)
4. Changes committed with conventional message format
5. SESSION_HANDOFF.md written if work spans multiple sessions

### Continuity Protocol

**Resuming work:**

1. Read SESSION_HANDOFF.md if it exists in the project root
2. Run the "Resume Commands" from the handoff
3. Check `git log` for recent context
4. Then begin new work

**Ending a session with incomplete work:**

1. Run `/handoff` to generate SESSION_HANDOFF.md
2. Run journal script for the memory system

---

## UI/UX Design System (Apple Minimal)

Design system contract: `~/.claude/uiux-contract/`

**Before any UI work**, agents **MUST** read:

- `design_tokens.json` — spacing, colors, radii, shadows, typography, motion
- `quality_gates.yaml` — 6 blocker + 4 major gates to self-check
- `components/<name>.yaml` — specs for button, input, dropdown, navbar, sidebar, modal, toast, table

Agents **MUST NOT** use arbitrary visual values — all colors, spacing, radii, shadows, font sizes, and motion timings **MUST** use design tokens.
