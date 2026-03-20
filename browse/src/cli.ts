import { chromium } from "playwright";
import { startServer, writeState, clearState } from "./server.js";
import { execCommand } from "./commands.js";
import { readFileSync, existsSync } from "fs";
import type { BrowseState, CommandContext } from "./types.js";
import crypto from "crypto";
import { initLogger, log } from "./logger.js";

const STATE_PATH = `${process.env.HOME}/.browse/state.json`;

function readState(): BrowseState | null {
  try {
    if (!existsSync(STATE_PATH)) return null;
    return JSON.parse(readFileSync(STATE_PATH, "utf-8")) as BrowseState;
  } catch {
    return null;
  }
}

function randomPort(): number {
  return 10000 + Math.floor(Math.random() * 50000);
}

async function start(): Promise<void> {
  const existing = readState();
  if (existing) {
    // Check if still running
    try {
      const res = await fetch(`http://127.0.0.1:${existing.port}/health`, {
        signal: AbortSignal.timeout(1000),
      });
      if (res.ok) {
        console.log(`Already running on port ${existing.port} (PID ${existing.pid})`);
        return;
      }
    } catch {
      // Dead process — clean up
      clearState();
    }
  }

  const token = crypto.randomUUID();

  console.log("Launching browser...");
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  let port: number = 0;
  let server: ReturnType<typeof startServer> | undefined;
  for (let attempt = 0; attempt < 5; attempt++) {
    port = randomPort();
    try {
      server = startServer({ browser, context, page, port, token });
      break;
    } catch (err) {
      if (attempt === 4) throw err;
    }
  }

  const versionPath = `${import.meta.dir}/../dist/.version`;
  const version = existsSync(versionPath) ? readFileSync(versionPath, "utf-8").trim() : "dev";

  const state: BrowseState = {
    pid: process.pid,
    port,
    token,
    startedAt: new Date().toISOString(),
    version,
  };

  writeState(state);
  initLogger();
  log("info", "daemon started", { port, pid: process.pid });
  console.log(`Browse daemon started on 127.0.0.1:${port} (PID ${process.pid})`);
  console.log(`Token: ${token}`);

  // Keep alive
  process.on("SIGINT", async () => {
    log("info", "daemon stopping", { signal: "SIGINT" });
    console.log("\nShutting down...");
    await browser.close();
    clearState();
    process.exit(0);
  });

  process.on("SIGTERM", async () => {
    log("info", "daemon stopping", { signal: "SIGTERM" });
    await browser.close();
    clearState();
    process.exit(0);
  });
}

async function stop(): Promise<void> {
  const state = readState();
  if (!state) {
    console.log("No running daemon found.");
    return;
  }

  try {
    await fetch(`http://127.0.0.1:${state.port}/stop`, {
      method: "POST",
      headers: { Authorization: `Bearer ${state.token}` },
      signal: AbortSignal.timeout(3000),
    });
    console.log("Daemon stopped.");
  } catch {
    // Force kill if HTTP fails
    try {
      process.kill(state.pid, "SIGTERM");
      console.log(`Sent SIGTERM to PID ${state.pid}`);
    } catch {
      console.log("Process already dead.");
    }
  }
  clearState();
}

async function status(): Promise<void> {
  const state = readState();
  if (!state) {
    console.log("No running daemon.");
    return;
  }

  try {
    const res = await fetch(`http://127.0.0.1:${state.port}/health`, {
      headers: { Authorization: `Bearer ${state.token}` },
      signal: AbortSignal.timeout(1000),
    });
    const data = (await res.json()) as { ok: boolean; uptime: number };
    console.log(`Running on 127.0.0.1:${state.port} (PID ${state.pid})`);
    console.log(`Uptime: ${Math.round(data.uptime)}s`);
    console.log(`Started: ${state.startedAt}`);
    console.log(`Version: ${state.version}`);
  } catch {
    console.log(`State file exists but daemon not responding (PID ${state.pid}).`);
    console.log("Run 'browse stop' to clean up.");
  }
}

async function exec(args: string[]): Promise<void> {
  const state = readState();
  if (!state) {
    console.error("No running daemon. Run 'browse start' first.");
    process.exit(1);
  }

  const command = args[0];
  if (!command) {
    console.error("Usage: browse exec <command> [--arg value ...]");
    process.exit(1);
  }

  // Parse remaining args as key=value pairs
  const cmdArgs: Record<string, unknown> = {};
  for (let i = 1; i < args.length; i++) {
    const arg = args[i];
    if (arg.startsWith("--")) {
      const key = arg.slice(2);
      const value = args[i + 1];
      if (value !== undefined && !value.startsWith("--")) {
        cmdArgs[key] = value;
        i++;
      } else {
        cmdArgs[key] = true;
      }
    }
  }

  try {
    const res = await fetch(`http://127.0.0.1:${state.port}/exec`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${state.token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ command, args: cmdArgs }),
      signal: AbortSignal.timeout(30000),
    });
    const data = await res.json();
    console.log(JSON.stringify(data, null, 2));
  } catch (err) {
    console.error(`Failed to execute: ${err instanceof Error ? err.message : err}`);
    process.exit(1);
  }
}

// ── CLI entry ──
const [subcommand, ...rest] = process.argv.slice(2);

switch (subcommand) {
  case "start":
    await start();
    break;
  case "stop":
    await stop();
    break;
  case "status":
    await status();
    break;
  case "exec":
    await exec(rest);
    break;
  default:
    console.log("Usage: browse <start|stop|status|exec> [args...]");
    console.log("");
    console.log("Commands:");
    console.log("  start     Launch the headless browser daemon");
    console.log("  stop      Stop the running daemon");
    console.log("  status    Show daemon status");
    console.log("  exec CMD  Execute a browser command");
    process.exit(subcommand ? 1 : 0);
}
