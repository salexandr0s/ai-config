import { describe, it, expect, vi, beforeEach } from "vitest";
import { execCommand, listCommands } from "../commands.js";
import type { CommandContext, ConsoleEntry } from "../types.js";

function makeCtx(overrides: Partial<CommandContext> = {}): CommandContext {
  return {
    page: {} as CommandContext["page"],
    browser: {} as CommandContext["browser"],
    context: {
      pages: () => [],
      newPage: vi.fn().mockResolvedValue({ url: () => "about:blank" }),
    } as unknown as CommandContext["context"],
    args: {},
    consoleBuffer: [],
    ...overrides,
  };
}

describe("execCommand", () => {
  it("returns error for unknown command", async () => {
    const result = await execCommand("nonexistent", makeCtx());
    expect(result.ok).toBe(false);
    expect(result.error).toContain("Unknown command");
    expect(result.duration).toBe(0);
  });

  it("catches handler exceptions", async () => {
    // Use a command that will throw due to missing page methods
    const ctx = makeCtx({
      page: {
        goto: vi.fn().mockRejectedValue(new Error("nav failed")),
      } as unknown as CommandContext["page"],
      args: { url: "http://example.com" },
    });
    const result = await execCommand("goto", ctx);
    expect(result.ok).toBe(false);
    expect(result.error).toBe("nav failed");
  });

  it("measures duration", async () => {
    const ctx = makeCtx({
      page: {
        url: vi.fn().mockReturnValue("http://example.com"),
      } as unknown as CommandContext["page"],
    });
    const result = await execCommand("url", ctx);
    expect(result.ok).toBe(true);
    expect(typeof result.duration).toBe("number");
    expect(result.duration).toBeGreaterThanOrEqual(0);
  });
});

describe("closetab", () => {
  it("opens blank tab before closing last tab", async () => {
    const newPageFn = vi.fn().mockResolvedValue({});
    const closeFn = vi.fn().mockResolvedValue(undefined);
    const ctx = makeCtx({
      page: { close: closeFn } as unknown as CommandContext["page"],
      context: {
        pages: () => [{}], // only 1 page
        newPage: newPageFn,
      } as unknown as CommandContext["context"],
    });
    const result = await execCommand("closetab", ctx);
    expect(result.ok).toBe(true);
    expect(newPageFn).toHaveBeenCalled();
    expect(closeFn).toHaveBeenCalled();
  });

  it("closes directly when multiple tabs exist", async () => {
    const newPageFn = vi.fn();
    const closeFn = vi.fn().mockResolvedValue(undefined);
    const ctx = makeCtx({
      page: { close: closeFn } as unknown as CommandContext["page"],
      context: {
        pages: () => [{}, {}], // 2 pages
        newPage: newPageFn,
      } as unknown as CommandContext["context"],
    });
    const result = await execCommand("closetab", ctx);
    expect(result.ok).toBe(true);
    expect(newPageFn).not.toHaveBeenCalled();
    expect(closeFn).toHaveBeenCalled();
  });
});

describe("scroll", () => {
  it("converts down direction to positive delta", async () => {
    const wheelFn = vi.fn().mockResolvedValue(undefined);
    const ctx = makeCtx({
      page: { mouse: { wheel: wheelFn } } as unknown as CommandContext["page"],
      args: { direction: "down", amount: 300 },
    });
    const result = await execCommand("scroll", ctx);
    expect(result.ok).toBe(true);
    expect(wheelFn).toHaveBeenCalledWith(0, 300);
  });

  it("converts up direction to negative delta", async () => {
    const wheelFn = vi.fn().mockResolvedValue(undefined);
    const ctx = makeCtx({
      page: { mouse: { wheel: wheelFn } } as unknown as CommandContext["page"],
      args: { direction: "up", amount: 200 },
    });
    const result = await execCommand("scroll", ctx);
    expect(result.ok).toBe(true);
    expect(wheelFn).toHaveBeenCalledWith(0, -200);
  });
});

describe("console", () => {
  it("drains and clears the console buffer", async () => {
    const buffer: ConsoleEntry[] = [
      { type: "log", text: "hello", timestamp: 1000 },
      { type: "error", text: "oops", timestamp: 2000 },
    ];
    const ctx = makeCtx({ consoleBuffer: buffer });
    const result = await execCommand("console", ctx);
    expect(result.ok).toBe(true);
    expect(result.data).toHaveLength(2);
    expect(buffer).toHaveLength(0);
  });
});

describe("listCommands", () => {
  it("returns all registered commands", () => {
    const cmds = listCommands();
    expect(cmds.length).toBeGreaterThan(0);
    const names = cmds.map((c) => c.name);
    expect(names).toContain("goto");
    expect(names).toContain("snapshot");
    expect(names).toContain("closetab");
  });
});
