import { appendFileSync, mkdirSync, renameSync, statSync } from "fs";

type LogLevel = "debug" | "info" | "warn" | "error";

interface LoggerConfig {
  logDir: string;
  logFile: string;
  maxBytes: number;
  minLevel: LogLevel;
}

const LEVEL_ORDER: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

let config: LoggerConfig = {
  logDir: `${process.env.HOME}/.browse`,
  logFile: "daemon.log",
  maxBytes: 5 * 1024 * 1024, // 5 MB
  minLevel: "info",
};

let initialized = false;

export function initLogger(overrides?: Partial<LoggerConfig>): void {
  if (overrides) {
    config = { ...config, ...overrides };
  }
  mkdirSync(config.logDir, { recursive: true });
  initialized = true;
}

function rotate(): void {
  const logPath = `${config.logDir}/${config.logFile}`;
  try {
    const stats = statSync(logPath);
    if (stats.size >= config.maxBytes) {
      renameSync(logPath, `${logPath}.1`);
    }
  } catch {
    // File doesn't exist yet — nothing to rotate
  }
}

export function log(
  level: LogLevel,
  message: string,
  meta?: Record<string, unknown>
): void {
  if (!initialized) return;
  if (LEVEL_ORDER[level] < LEVEL_ORDER[config.minLevel]) return;

  rotate();

  const entry = JSON.stringify({
    ts: new Date().toISOString(),
    level,
    msg: message,
    ...(meta && Object.keys(meta).length > 0 ? { meta } : {}),
  });

  try {
    appendFileSync(`${config.logDir}/${config.logFile}`, entry + "\n");
  } catch {
    // Logging must never crash the daemon
  }
}
