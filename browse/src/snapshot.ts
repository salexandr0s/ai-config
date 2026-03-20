import type { Page } from "playwright";
import type { SnapshotNode } from "./types.js";
import { parseAriaSnapshot } from "./aria-snapshot-adapter.js";

interface SnapshotOptions {
  compact?: boolean;
  depth?: number;
  interactive?: boolean;
}

/** Shape returned by the legacy page.accessibility.snapshot() API */
interface AccessibilityNode {
  role: string;
  name?: string;
  value?: string;
  children?: AccessibilityNode[];
}

export async function takeSnapshot(page: Page, options: SnapshotOptions = {}): Promise<SnapshotNode[]> {
  let refCounter = 0;
  const nextRef = (role: string): string => {
    refCounter++;
    const prefix = role === "link" ? "l" : role === "button" ? "b" : role === "textbox" ? "t" : "e";
    return `@${prefix}${refCounter}`;
  };

  // Primary: use ariaSnapshot() (Playwright 1.49+)
  try {
    const ariaText = await page.locator(":root").ariaSnapshot();
    return parseAriaSnapshot(ariaText);
  } catch {
    // Fall back to deprecated API for older Playwright versions
  }

  // Fallback: deprecated page.accessibility.snapshot()
  const accessor = (page as unknown as { accessibility: { snapshot: (opts: { interestingOnly: boolean }) => Promise<AccessibilityNode | null> } }).accessibility;
  if (!accessor) return [];
  const tree = await accessor.snapshot({ interestingOnly: options.interactive ?? false });
  if (!tree) return [];
  return flattenTree(tree, 0, options.depth ?? Infinity, nextRef);
}

export function flattenTree(
  node: AccessibilityNode,
  depth: number,
  maxDepth: number,
  nextRef: (role: string) => string
): SnapshotNode[] {
  if (depth > maxDepth) return [];

  const ref = nextRef(node.role);
  const result: SnapshotNode = {
    ref,
    role: node.role,
    ...(node.name ? { name: node.name } : {}),
    ...(node.value ? { text: String(node.value) } : {}),
  };

  const children: SnapshotNode[] = [];
  if (node.children) {
    for (const child of node.children) {
      children.push(...flattenTree(child, depth + 1, maxDepth, nextRef));
    }
  }

  if (children.length > 0) {
    result.children = children;
  }

  return [result];
}

const INTERACTIVE_ROLES = ["button", "link", "textbox", "combobox", "checkbox"];

export function formatSnapshot(nodes: SnapshotNode[], indent = 0, compact = false): string {
  const lines: string[] = [];
  for (const node of nodes) {
    if (compact && !node.name && !INTERACTIVE_ROLES.includes(node.role)) {
      // In compact mode, skip non-interactive unnamed nodes but recurse into children
      if (node.children) {
        lines.push(formatSnapshot(node.children, indent, compact));
      }
      continue;
    }
    const pad = "  ".repeat(indent);
    const parts = [node.ref, node.role];
    if (node.name) parts.push(`"${node.name}"`);
    if (node.text) parts.push(`= "${node.text}"`);
    lines.push(`${pad}${parts.join(" ")}`);
    if (node.children) {
      lines.push(formatSnapshot(node.children, indent + 1, compact));
    }
  }
  return lines.join("\n");
}
