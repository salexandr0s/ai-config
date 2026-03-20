export interface BrowseState {
  pid: number;
  port: number;
  token: string;
  startedAt: string;
  version: string;
}

export interface CommandResult {
  ok: boolean;
  data?: unknown;
  error?: string;
  duration: number;
}

export interface SnapshotNode {
  ref: string;
  role: string;
  name?: string;
  text?: string;
  children?: SnapshotNode[];
}

export type CommandCategory = "READ" | "WRITE" | "META";

export interface CommandDef {
  name: string;
  category: CommandCategory;
  description: string;
  args?: Record<string, { type: string; required?: boolean; description: string }>;
  handler: (ctx: CommandContext) => Promise<unknown>;
}

export interface ConsoleEntry {
  type: string;
  text: string;
  timestamp: number;
}

export interface CommandContext {
  page: import("playwright").Page;
  browser: import("playwright").Browser;
  context: import("playwright").BrowserContext;
  args: Record<string, unknown>;
  consoleBuffer: ConsoleEntry[];
}
