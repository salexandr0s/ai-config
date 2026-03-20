# Snapshot & Ref System Guide

## What is a Snapshot?

The `snapshot` command captures the page's accessibility tree and assigns short refs to each element. This provides a machine-readable view of the page that's more reliable than CSS selectors for dynamic pages.

## Ref Format

Refs use a prefix based on the element role:

| Prefix | Role     | Example |
|--------|----------|---------|
| `@b`   | button   | `@b1`   |
| `@l`   | link     | `@l2`   |
| `@t`   | textbox  | `@t3`   |
| `@e`   | other    | `@e4`   |

## Usage

### Take a snapshot
```bash
browse exec snapshot
```

Output:
```
@e1 WebArea "Example Page"
  @l1 link "Home"
  @l2 link "About"
  @t1 textbox "Search"
  @b1 button "Submit"
```

### Interactive-only snapshot
```bash
browse exec snapshot --interactive true
```

Shows only interactive elements (buttons, links, inputs) — useful for understanding what actions are available.

### Compact snapshot
```bash
browse exec snapshot --compact true
```

Shorter output, omitting less important nodes.

### Depth-limited snapshot
```bash
browse exec snapshot --depth 2
```

Only show first 2 levels of the tree.

## Tips

- Take a snapshot first to understand the page structure
- Use `--interactive true` when planning form filling or navigation
- Refs reset on each snapshot call — don't cache them across snapshots
- For complex pages, use `--depth` to get a high-level view first
