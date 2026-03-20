import { execSync } from "child_process";

interface CookieImportResult {
  source: string;
  count: number;
  error?: string;
}

const BROWSER_COOKIE_PATHS: Record<string, string> = {
  chrome: "$HOME/Library/Application Support/Google/Chrome/Default/Cookies",
  arc: "$HOME/Library/Application Support/Arc/User Data/Default/Cookies",
  brave: "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Cookies",
  edge: "$HOME/Library/Application Support/Microsoft Edge/Default/Cookies",
};

export function getAvailableBrowsers(): string[] {
  const available: string[] = [];
  for (const [name, pathTemplate] of Object.entries(BROWSER_COOKIE_PATHS)) {
    const path = pathTemplate.replace("$HOME", process.env.HOME ?? "");
    try {
      execSync(`test -f "${path}"`, { stdio: "ignore" });
      available.push(name);
    } catch {
      // Browser not installed or no cookies
    }
  }
  return available;
}

export async function importCookies(
  context: import("playwright").BrowserContext,
  browserName: string,
  domain?: string
): Promise<CookieImportResult> {
  const pathTemplate = BROWSER_COOKIE_PATHS[browserName.toLowerCase()];
  if (!pathTemplate) {
    return { source: browserName, count: 0, error: `Unknown browser: ${browserName}` };
  }

  const dbPath = pathTemplate.replace("$HOME", process.env.HOME ?? "");

  try {
    // Query cookies from SQLite database
    // Note: Chrome-based browsers encrypt cookies on macOS using the Keychain
    // This reads the raw database — decryption requires additional steps
    const safeDomain = domain?.replace(/[^a-zA-Z0-9._-]/g, "");
    const query = safeDomain
      ? `SELECT name, value, host_key, path, is_secure, expires_utc FROM cookies WHERE host_key LIKE '%${safeDomain}%' LIMIT 100`
      : `SELECT name, value, host_key, path, is_secure, expires_utc FROM cookies LIMIT 100`;

    const output = execSync(`sqlite3 -json "${dbPath}" "${query}" 2>/dev/null`, {
      encoding: "utf-8",
      timeout: 5000,
    });

    const rows = JSON.parse(output || "[]") as Array<{
      name: string;
      value: string;
      host_key: string;
      path: string;
      is_secure: number;
      expires_utc: number;
    }>;

    const cookies = rows.map((row) => ({
      name: row.name,
      value: row.value,
      domain: row.host_key,
      path: row.path || "/",
      secure: row.is_secure === 1,
      expires: row.expires_utc > 0 ? row.expires_utc / 1000000 - 11644473600 : -1,
    }));

    if (cookies.length > 0) {
      await context.addCookies(cookies);
    }

    return { source: browserName, count: cookies.length };
  } catch (err) {
    return {
      source: browserName,
      count: 0,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}
