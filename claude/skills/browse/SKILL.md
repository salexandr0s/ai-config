---
name: browse
description: |
  Persistent headless browser for web interaction, QA testing, and scraping.
  ~100ms per command after first call. Use when the user needs to interact
  with a live website, verify UI, fill forms, extract data, or test visually.
metadata:
  author: nationalbank
  version: "1.0.0"
---

# Browse — Persistent Headless Browser

## When to Use

- User wants to interact with a live website
- QA testing (forms, navigation, visual verification)
- Scraping or extracting data from web pages
- Verifying deployed applications
- Testing UI changes in a real browser

## When NOT to Use

- One-off Playwright automation → use MCP Playwright plugin instead
- Unit/integration testing → use vitest/jest
- Static analysis → use existing code tools

## Methodology

### 1. Ensure Daemon

```bash
browse-ctl ensure
```

This starts the headless Chromium daemon if not already running.

### 2. Navigate

```bash
browse exec goto --url "https://example.com"
```

### 3. Inspect

```bash
browse exec snapshot --interactive true    # Accessibility tree with refs
browse exec text --selector "main"         # Get text content
browse exec links                          # List all links
browse exec forms                          # List forms and fields
```

### 4. Interact

```bash
browse exec click --selector "#submit-btn"
browse exec fill --selector "#email" --value "test@example.com"
browse exec select --selector "#country" --value "US"
browse exec press --key "Enter"
```

### 5. Verify

```bash
browse exec screenshot --path "/tmp/result.png"
browse exec console                        # Check for errors
browse exec js --expression "document.title"
```

## Ref System

The `snapshot` command returns elements with refs like `@b1` (button), `@l2` (link), `@t3` (textbox). Use these to identify elements for interaction.

## Security

- Daemon binds to localhost only (127.0.0.1)
- Random port between 10000-60000
- UUID bearer token required for all commands (except /health)
- State file at `~/.browse/state.json` with mode 0600
- Cookie import reads local browser databases in-process only

## Coexistence with MCP Playwright

- **Browse daemon**: persistent sessions, cookie persistence, fast repeated commands
- **MCP Playwright**: one-off automation, isolated contexts, managed lifecycle

Use browse for QA workflows and interactive exploration. Use MCP for test automation.
