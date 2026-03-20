import type { BrowseState, CommandContext, ConsoleEntry } from "./types.js";
import { execCommand, listCommands } from "./commands.js";
import type { Browser, BrowserContext, Page } from "playwright";
import { mkdirSync, writeFileSync, chmodSync, unlinkSync } from "fs";
import { log } from "./logger.js";

interface ServerConfig {
  browser: Browser;
  context: BrowserContext;
  page: Page;
  port: number;
  token: string;
}

export function startServer(config: ServerConfig): ReturnType<typeof Bun.serve> {
  const { browser, context, port, token } = config;
  let currentPage = config.page;

  // Persistent console message buffer (capped to prevent unbounded growth)
  const MAX_CONSOLE_BUFFER = 1000;
  const consoleBuffer: ConsoleEntry[] = [];

  function pushConsole(entry: ConsoleEntry): void {
    consoleBuffer.push(entry);
    if (consoleBuffer.length > MAX_CONSOLE_BUFFER) {
      consoleBuffer.splice(0, consoleBuffer.length - MAX_CONSOLE_BUFFER);
    }
  }

  currentPage.on("console", (msg) => {
    pushConsole({ type: msg.type(), text: msg.text(), timestamp: Date.now() });
  });
  context.on("page", (page) => {
    page.on("console", (msg) => {
      pushConsole({ type: msg.type(), text: msg.text(), timestamp: Date.now() });
    });
  });

  const server = Bun.serve({
    port,
    hostname: "127.0.0.1",

    async fetch(req) {
      const url = new URL(req.url);

      // Health check (no auth required)
      if (url.pathname === "/health") {
        return Response.json({ ok: true, uptime: process.uptime() });
      }

      // Auth check
      const auth = req.headers.get("Authorization");
      if (auth !== `Bearer ${token}`) {
        log("warn", "unauthorized request", { path: url.pathname });
        return Response.json({ ok: false, error: "Unauthorized" }, { status: 401 });
      }

      // List commands
      if (url.pathname === "/commands" && req.method === "GET") {
        const cmds = listCommands().map((c) => ({
          name: c.name,
          category: c.category,
          description: c.description,
          args: c.args,
        }));
        return Response.json({ ok: true, data: cmds });
      }

      // Execute command
      if (url.pathname === "/exec" && req.method === "POST") {
        const body = (await req.json()) as { command: string; args?: Record<string, unknown> };
        if (!body.command) {
          return Response.json({ ok: false, error: "Missing 'command' field" }, { status: 400 });
        }

        // Update current page reference (might have changed via tab operations)
        const pages = context.pages();
        if (pages.length > 0 && !pages.includes(currentPage)) {
          currentPage = pages[pages.length - 1];
        }

        const ctx: CommandContext = {
          page: currentPage,
          browser,
          context,
          args: body.args ?? {},
          consoleBuffer,
        };

        const result = await execCommand(body.command, ctx);
        log("info", "exec", { command: body.command, duration: result.duration, ok: result.ok });
        return Response.json(result);
      }

      // Stop server
      if (url.pathname === "/stop" && req.method === "POST") {
        log("info", "stop requested");
        setTimeout(async () => {
          await browser.close();
          clearState();
          process.exit(0);
        }, 100);
        return Response.json({ ok: true, data: "Shutting down" });
      }

      return Response.json({ ok: false, error: "Not found" }, { status: 404 });
    },
  });

  return server;
}

export function writeState(state: BrowseState): void {
  const stateDir = `${process.env.HOME}/.browse`;
  const statePath = `${stateDir}/state.json`;
  mkdirSync(stateDir, { recursive: true });
  writeFileSync(statePath, JSON.stringify(state, null, 2));
  chmodSync(statePath, 0o600);
}

export function clearState(): void {
  const statePath = `${process.env.HOME}/.browse/state.json`;
  try {
    unlinkSync(statePath);
  } catch {
    // Already gone
  }
}
