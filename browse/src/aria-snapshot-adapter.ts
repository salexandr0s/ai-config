import type { SnapshotNode } from "./types.js";

/**
 * Parse Playwright's ariaSnapshot() indentation-based string into SnapshotNode[].
 *
 * Input format:
 *   - document "Page Title":
 *     - button "Click me"
 *     - link "Home"
 *
 * Each line: optional indent, "- ", role, optional " \"name\"", optional ":"
 */

interface ParsedLine {
  indent: number;
  role: string;
  name?: string;
  hasChildren: boolean;
}

function parseLine(line: string): ParsedLine | null {
  // Match: leading spaces, "- ", role, optional quoted name, optional ":"
  const match = line.match(/^(\s*)- (\w+)(?:\s+"([^"]*)")?(:)?$/);
  if (!match) return null;
  return {
    indent: match[1].length,
    role: match[2],
    name: match[3],
    hasChildren: match[4] === ":",
  };
}

function refPrefix(role: string): string {
  switch (role) {
    case "link": return "l";
    case "button": return "b";
    case "textbox": return "t";
    default: return "e";
  }
}

export function parseAriaSnapshot(input: string): SnapshotNode[] {
  const lines = input.split("\n").filter((l) => l.trim().length > 0);
  if (lines.length === 0) return [];

  let refCounter = 0;
  const nextRef = (role: string): string => {
    refCounter++;
    return `@${refPrefix(role)}${refCounter}`;
  };

  // Parse all lines
  const parsed: (ParsedLine & { lineIndex: number })[] = [];
  for (let i = 0; i < lines.length; i++) {
    const p = parseLine(lines[i]);
    if (p) parsed.push({ ...p, lineIndex: i });
  }

  if (parsed.length === 0) return [];

  // Build tree from indentation
  function buildNodes(items: typeof parsed, parentIndent: number): SnapshotNode[] {
    const result: SnapshotNode[] = [];
    let i = 0;

    while (i < items.length) {
      const item = items[i];
      if (item.indent <= parentIndent && result.length > 0) break;
      if (item.indent < parentIndent) break;

      const node: SnapshotNode = {
        ref: nextRef(item.role),
        role: item.role,
        ...(item.name ? { name: item.name } : {}),
      };

      // Collect children (items with greater indent following this one)
      if (item.hasChildren) {
        const childItems: typeof parsed = [];
        let j = i + 1;
        while (j < items.length && items[j].indent > item.indent) {
          childItems.push(items[j]);
          j++;
        }
        if (childItems.length > 0) {
          node.children = buildNodes(childItems, item.indent);
        }
        i = j;
      } else {
        i++;
      }

      result.push(node);
    }

    return result;
  }

  return buildNodes(parsed, parsed[0].indent - 1);
}
