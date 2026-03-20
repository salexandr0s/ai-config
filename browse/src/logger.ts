import { appendFileSync, existsSync, mkdirSync, renameSync, statSync, unlinkSync } from "fs";

type LogLevel = "debug" | "info" | "warn" | "error";

interface LoggerConfig {
  logDir: string;
  logFile: string;
  maxBytes: number;
  maxBackups: number;
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
  maxBackups: 2,
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
    if (stats.size < config.maxBytes) return;
  } catch {
    return; // File doesn't exist yet
  }

  // Shift backups: .2 → delete, .1 → .2, current → .1
  for (let i = config.maxBackups; i >= 1; i--) {
    const src = i === 1 ? logPath : `${logPath}.${i - 1}`;
    const dst = `${logPath}.${i}`;
    try {
      if (i === config.maxBackups && existsSync(dst)) {
        unlinkSync(dst);
      }
      if (existsSync(src)) {
        renameSync(src, dst);
      }
    } catch {
      // Best-effort rotation — never crash the daemon
    }
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
