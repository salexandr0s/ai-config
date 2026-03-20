import type { Page, Browser, BrowserContext } from "playwright";
import type { CommandDef, CommandContext, CommandResult } from "./types.js";
import { takeSnapshot, formatSnapshot } from "./snapshot.js";
import { log } from "./logger.js";

const commands = new Map<string, CommandDef>();

function register(cmd: CommandDef): void {
  commands.set(cmd.name, cmd);
}

export function getCommand(name: string): CommandDef | undefined {
  return commands.get(name);
}

export function listCommands(): CommandDef[] {
  return Array.from(commands.values());
}

export async function execCommand(
  name: string,
  ctx: CommandContext
): Promise<CommandResult> {
  const start = performance.now();
  const cmd = commands.get(name);
  if (!cmd) {
    return { ok: false, error: `Unknown command: ${name}`, duration: 0 };
  }
  try {
    const data = await cmd.handler(ctx);
    return { ok: true, data, duration: performance.now() - start };
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    log("error", "command failed", { command: name, error: errorMsg });
    return {
      ok: false,
      error: errorMsg,
      duration: performance.now() - start,
    };
  }
}

// ── Navigation ──

register({
  name: "goto",
  category: "WRITE",
  description: "Navigate to a URL",
  args: { url: { type: "string", required: true, description: "URL to navigate to" } },
  handler: async (ctx) => {
    const url = String(ctx.args.url);
    await ctx.page.goto(url, { waitUntil: "domcontentloaded" });
    return { url: ctx.page.url(), title: await ctx.page.title() };
  },
});

register({
  name: "back",
  category: "WRITE",
  description: "Navigate back",
  handler: async (ctx) => {
    await ctx.page.goBack();
    return { url: ctx.page.url() };
  },
});

register({
  name: "forward",
  category: "WRITE",
  description: "Navigate forward",
  handler: async (ctx) => {
    await ctx.page.goForward();
    return { url: ctx.page.url() };
  },
});

register({
  name: "reload",
  category: "WRITE",
  description: "Reload current page",
  handler: async (ctx) => {
    await ctx.page.reload();
    return { url: ctx.page.url() };
  },
});

register({
  name: "url",
  category: "READ",
  description: "Get current URL",
  handler: async (ctx) => ctx.page.url(),
});

// ── Reading ──

register({
  name: "text",
  category: "READ",
  description: "Get text content of element or page",
  args: { selector: { type: "string", required: false, description: "CSS selector (default: body)" } },
  handler: async (ctx) => {
    const sel = String(ctx.args.selector || "body");
    return ctx.page.textContent(sel);
  },
});

register({
  name: "html",
  category: "READ",
  description: "Get HTML of element or page",
  args: { selector: { type: "string", required: false, description: "CSS selector (default: body)" } },
  handler: async (ctx) => {
    const sel = String(ctx.args.selector || "body");
    return ctx.page.innerHTML(sel);
  },
});

register({
  name: "links",
  category: "READ",
  description: "List all links on the page",
  handler: async (ctx) => {
    return ctx.page.$$eval("a[href]", (els) =>
      els.map((a) => ({ text: a.textContent?.trim(), href: a.getAttribute("href") }))
    );
  },
});

register({
  name: "forms",
  category: "READ",
  description: "List all forms and their fields",
  handler: async (ctx) => {
    return ctx.page.$$eval("form", (forms) =>
      forms.map((f, i) => ({
        index: i,
        action: f.action,
        method: f.method,
        fields: Array.from(f.elements).map((el) => ({
          tag: el.tagName.toLowerCase(),
          type: (el as HTMLInputElement).type || undefined,
          name: (el as HTMLInputElement).name || undefined,
          id: el.id || undefined,
        })),
      }))
    );
  },
});

register({
  name: "accessibility",
  category: "READ",
  description: "Get accessibility tree snapshot",
  handler: async (ctx) => {
    // Primary: ariaSnapshot() (Playwright 1.49+)
    try {
      return await ctx.page.locator(":root").ariaSnapshot();
    } catch {
      // Fallback for older Playwright versions
      const accessor = (ctx.page as unknown as { accessibility: { snapshot: () => Promise<unknown> } }).accessibility;
      if (accessor) return accessor.snapshot();
      return null;
    }
  },
});

// ── Interaction ──

register({
  name: "click",
  category: "WRITE",
  description: "Click an element",
  args: { selector: { type: "string", required: true, description: "CSS selector to click" } },
  handler: async (ctx) => {
    await ctx.page.click(String(ctx.args.selector));
    return { clicked: ctx.args.selector };
  },
});

register({
  name: "fill",
  category: "WRITE",
  description: "Fill a form field",
  args: {
    selector: { type: "string", required: true, description: "CSS selector" },
    value: { type: "string", required: true, description: "Value to fill" },
  },
  handler: async (ctx) => {
    await ctx.page.fill(String(ctx.args.selector), String(ctx.args.value));
    return { filled: ctx.args.selector, value: ctx.args.value };
  },
});

register({
  name: "select",
  category: "WRITE",
  description: "Select option in dropdown",
  args: {
    selector: { type: "string", required: true, description: "CSS selector" },
    value: { type: "string", required: true, description: "Option value" },
  },
  handler: async (ctx) => {
    await ctx.page.selectOption(String(ctx.args.selector), String(ctx.args.value));
    return { selected: ctx.args.value };
  },
});

register({
  name: "hover",
  category: "WRITE",
  description: "Hover over an element",
  args: { selector: { type: "string", required: true, description: "CSS selector" } },
  handler: async (ctx) => {
    await ctx.page.hover(String(ctx.args.selector));
    return { hovered: ctx.args.selector };
  },
});

register({
  name: "type",
  category: "WRITE",
  description: "Type text (keystroke by keystroke)",
  args: {
    selector: { type: "string", required: true, description: "CSS selector" },
    text: { type: "string", required: true, description: "Text to type" },
  },
  handler: async (ctx) => {
    await ctx.page.type(String(ctx.args.selector), String(ctx.args.text));
    return { typed: ctx.args.text };
  },
});

register({
  name: "press",
  category: "WRITE",
  description: "Press a keyboard key",
  args: { key: { type: "string", required: true, description: "Key name (e.g. Enter, Tab, Escape)" } },
  handler: async (ctx) => {
    await ctx.page.keyboard.press(String(ctx.args.key));
    return { pressed: ctx.args.key };
  },
});

register({
  name: "scroll",
  category: "WRITE",
  description: "Scroll the page or element",
  args: {
    direction: { type: "string", required: false, description: "up or down (default: down)" },
    amount: { type: "number", required: false, description: "Pixels to scroll (default: 500)" },
  },
  handler: async (ctx) => {
    const dir = String(ctx.args.direction || "down");
    const amount = Number(ctx.args.amount || 500);
    const delta = dir === "up" ? -amount : amount;
    await ctx.page.mouse.wheel(0, delta);
    return { scrolled: dir, amount };
  },
});

register({
  name: "wait",
  category: "WRITE",
  description: "Wait for selector, navigation, or timeout",
  args: {
    selector: { type: "string", required: false, description: "CSS selector to wait for" },
    timeout: { type: "number", required: false, description: "Timeout in ms (default: 5000)" },
  },
  handler: async (ctx) => {
    const timeout = Number(ctx.args.timeout || 5000);
    if (ctx.args.selector) {
      await ctx.page.waitForSelector(String(ctx.args.selector), { timeout });
      return { found: ctx.args.selector };
    }
    await new Promise((r) => setTimeout(r, timeout));
    return { waited: timeout };
  },
});

// ── Inspection ──

register({
  name: "js",
  category: "READ",
  description: "Execute JavaScript in the page context",
  args: { expression: { type: "string", required: true, description: "JavaScript to evaluate" } },
  handler: async (ctx) => ctx.page.evaluate(String(ctx.args.expression)),
});

register({
  name: "console",
  category: "READ",
  description: "Get console messages since last check",
  handler: async (ctx) => {
    const messages = [...ctx.consoleBuffer];
    ctx.consoleBuffer.length = 0;
    return messages;
  },
});

register({
  name: "cookies",
  category: "READ",
  description: "Get cookies for current page",
  handler: async (ctx) => ctx.context.cookies(),
});

register({
  name: "storage",
  category: "READ",
  description: "Get localStorage contents",
  handler: async (ctx) => {
    return ctx.page.evaluate(() => {
      const items: Record<string, string> = {};
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key) items[key] = localStorage.getItem(key) ?? "";
      }
      return items;
    });
  },
});

// ── Visual ──

register({
  name: "screenshot",
  category: "READ",
  description: "Take a screenshot",
  args: {
    path: { type: "string", required: false, description: "File path to save (default: /tmp/browse-screenshot.png)" },
    fullPage: { type: "boolean", required: false, description: "Capture full page (default: false)" },
  },
  handler: async (ctx) => {
    const path = String(ctx.args.path || "/tmp/browse-screenshot.png");
    const fullPage = Boolean(ctx.args.fullPage);
    await ctx.page.screenshot({ path, fullPage });
    return { saved: path };
  },
});

register({
  name: "pdf",
  category: "READ",
  description: "Save page as PDF",
  args: { path: { type: "string", required: false, description: "File path (default: /tmp/browse-page.pdf)" } },
  handler: async (ctx) => {
    const path = String(ctx.args.path || "/tmp/browse-page.pdf");
    await ctx.page.pdf({ path });
    return { saved: path };
  },
});

// ── Snapshot ──

register({
  name: "snapshot",
  category: "READ",
  description: "Take accessibility snapshot with ref system",
  args: {
    compact: { type: "boolean", required: false, description: "Compact output" },
    depth: { type: "number", required: false, description: "Max tree depth" },
    interactive: { type: "boolean", required: false, description: "Only interactive elements" },
  },
  handler: async (ctx) => {
    const compact = Boolean(ctx.args.compact);
    const nodes = await takeSnapshot(ctx.page, {
      compact,
      depth: ctx.args.depth ? Number(ctx.args.depth) : undefined,
      interactive: Boolean(ctx.args.interactive),
    });
    return formatSnapshot(nodes, 0, compact);
  },
});

// ── Meta ──

register({
  name: "status",
  category: "META",
  description: "Get browser and page status",
  handler: async (ctx) => ({
    url: ctx.page.url(),
    title: await ctx.page.title(),
    viewport: ctx.page.viewportSize(),
    contexts: ctx.browser.contexts().length,
  }),
});

register({
  name: "tabs",
  category: "READ",
  description: "List open tabs",
  handler: async (ctx) => {
    const pages = ctx.context.pages();
    const results = await Promise.all(
      pages.map(async (p, i) => ({ index: i, url: p.url(), title: await p.title() }))
    );
    return results;
  },
});

register({
  name: "newtab",
  category: "WRITE",
  description: "Open a new tab",
  args: { url: { type: "string", required: false, description: "URL to open" } },
  handler: async (ctx) => {
    const page = await ctx.context.newPage();
    if (ctx.args.url) {
      await page.goto(String(ctx.args.url), { waitUntil: "domcontentloaded" });
    }
    return { url: page.url() };
  },
});

register({
  name: "closetab",
  category: "WRITE",
  description: "Close current tab",
  handler: async (ctx) => {
    const pages = ctx.context.pages();
    if (pages.length <= 1) {
      // Don't close the last tab — open a blank one first
      await ctx.context.newPage();
    }
    await ctx.page.close();
    return { closed: true };
  },
});
