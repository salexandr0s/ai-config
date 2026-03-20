import { describe, it, expect, vi, beforeEach } from "vitest";
import { flattenTree, formatSnapshot, takeSnapshot } from "../snapshot.js";
import type { SnapshotNode } from "../types.js";

describe("flattenTree", () => {
  let refCounter: number;
  const nextRef = (role: string): string => {
    refCounter++;
    const prefix = role === "link" ? "l" : role === "button" ? "b" : role === "textbox" ? "t" : "e";
    return `@${prefix}${refCounter}`;
  };

  beforeEach(() => {
    refCounter = 0;
  });

  it("returns single node for leaf element", () => {
    const node = { role: "button", name: "Submit", children: [] };
    const result = flattenTree(node as never, 0, Infinity, nextRef);
    expect(result).toHaveLength(1);
    expect(result[0].role).toBe("button");
    expect(result[0].name).toBe("Submit");
    expect(result[0].ref).toBe("@b1");
  });

  it("recurses into children", () => {
    const node = {
      role: "document",
      name: "Page",
      children: [
        { role: "link", name: "Home", children: [] },
        { role: "button", name: "Click", children: [] },
      ],
    };
    const result = flattenTree(node as never, 0, Infinity, nextRef);
    expect(result).toHaveLength(1);
    expect(result[0].children).toHaveLength(2);
    expect(result[0].children![0].ref).toBe("@l2");
    expect(result[0].children![1].ref).toBe("@b3");
  });

  it("respects depth limit", () => {
    const node = {
      role: "document",
      name: "Page",
      children: [{ role: "button", name: "Deep", children: [] }],
    };
    const result = flattenTree(node as never, 0, 0, nextRef);
    expect(result).toHaveLength(1);
    expect(result[0].children).toBeUndefined();
  });

  it("assigns ref prefix per role", () => {
    const roles = [
      { role: "link", prefix: "l" },
      { role: "button", prefix: "b" },
      { role: "textbox", prefix: "t" },
      { role: "heading", prefix: "e" },
    ];
    for (const { role, prefix } of roles) {
      refCounter = 0;
      const node = { role, name: "test", children: [] };
      const result = flattenTree(node as never, 0, Infinity, nextRef);
      expect(result[0].ref).toBe(`@${prefix}1`);
    }
  });

  it("includes value as text field", () => {
    const node = { role: "textbox", name: "Email", value: "a@b.com", children: [] };
    const result = flattenTree(node as never, 0, Infinity, nextRef);
    expect(result[0].text).toBe("a@b.com");
  });
});

describe("formatSnapshot", () => {
  it("returns empty string for empty input", () => {
    expect(formatSnapshot([])).toBe("");
  });

  it("formats single node", () => {
    const nodes: SnapshotNode[] = [{ ref: "@b1", role: "button", name: "OK" }];
    expect(formatSnapshot(nodes)).toBe('@b1 button "OK"');
  });

  it("skips non-interactive unnamed nodes in compact mode", () => {
    const nodes: SnapshotNode[] = [
      {
        ref: "@e1",
        role: "generic",
        children: [{ ref: "@b2", role: "button", name: "Click" }],
      },
    ];
    const result = formatSnapshot(nodes, 0, true);
    expect(result).toContain("@b2");
    expect(result).not.toContain("@e1");
  });

  it("indents children", () => {
    const nodes: SnapshotNode[] = [
      {
        ref: "@e1",
        role: "document",
        name: "Page",
        children: [{ ref: "@b2", role: "button", name: "OK" }],
      },
    ];
    const result = formatSnapshot(nodes);
    const lines = result.split("\n");
    expect(lines[0]).toBe('@e1 document "Page"');
    expect(lines[1]).toBe('  @b2 button "OK"');
  });

  it("includes text values", () => {
    const nodes: SnapshotNode[] = [{ ref: "@t1", role: "textbox", name: "Email", text: "hi" }];
    expect(formatSnapshot(nodes)).toBe('@t1 textbox "Email" = "hi"');
  });
});

describe("takeSnapshot", () => {
  it("returns empty array when accessibility tree is null", async () => {
    const mockPage = {
      accessibility: {
        snapshot: vi.fn().mockResolvedValue(null),
      },
    };
    const result = await takeSnapshot(mockPage as never);
    expect(result).toEqual([]);
  });

  it("returns structured nodes from accessibility tree", async () => {
    const mockPage = {
      accessibility: {
        snapshot: vi.fn().mockResolvedValue({
          role: "document",
          name: "Test",
          children: [
            { role: "button", name: "Submit", children: [] },
          ],
        }),
      },
    };
    const result = await takeSnapshot(mockPage as never);
    expect(result).toHaveLength(1);
    expect(result[0].role).toBe("document");
    expect(result[0].children).toHaveLength(1);
    expect(result[0].children![0].role).toBe("button");
  });
});
