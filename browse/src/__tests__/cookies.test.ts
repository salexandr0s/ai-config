import { describe, it, expect, vi, beforeEach } from "vitest";
import { getAvailableBrowsers, importCookies } from "../cookies.js";
import { execSync } from "child_process";

vi.mock("child_process", () => ({
  execSync: vi.fn(),
}));

const mockExecSync = vi.mocked(execSync);

describe("getAvailableBrowsers", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns browsers whose cookie files exist", () => {
    // First call succeeds (chrome), rest throw
    mockExecSync
      .mockImplementationOnce(() => Buffer.from(""))  // chrome exists
      .mockImplementationOnce(() => { throw new Error("not found"); })  // arc
      .mockImplementationOnce(() => { throw new Error("not found"); })  // brave
      .mockImplementationOnce(() => { throw new Error("not found"); }); // edge

    const result = getAvailableBrowsers();
    expect(result).toContain("chrome");
    expect(result).not.toContain("arc");
  });

  it("returns empty array when no browsers found", () => {
    mockExecSync.mockImplementation(() => { throw new Error("not found"); });
    const result = getAvailableBrowsers();
    expect(result).toEqual([]);
  });
});

describe("importCookies", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns error for unknown browser", async () => {
    const ctx = { addCookies: vi.fn() } as unknown as import("playwright").BrowserContext;
    const result = await importCookies(ctx, "firefox");
    expect(result.error).toContain("Unknown browser");
    expect(result.count).toBe(0);
  });

  it("sanitizes domain input", async () => {
    const ctx = { addCookies: vi.fn() } as unknown as import("playwright").BrowserContext;
    mockExecSync.mockReturnValue("[]");
    await importCookies(ctx, "chrome", "example.com; DROP TABLE cookies;--");
    const query = mockExecSync.mock.calls[0][0] as string;
    expect(query).not.toContain("DROP TABLE");
    expect(query).toContain("example.com");
  });

  it("converts Windows epoch to Unix epoch", async () => {
    const addCookies = vi.fn();
    const ctx = { addCookies } as unknown as import("playwright").BrowserContext;
    // expires_utc in Chrome format: microseconds since 1601-01-01
    const chromeEpoch = 13300000000000000; // some future date
    mockExecSync.mockReturnValue(
      JSON.stringify([
        {
          name: "session",
          value: "abc",
          host_key: ".example.com",
          path: "/",
          is_secure: 1,
          expires_utc: chromeEpoch,
        },
      ])
    );
    await importCookies(ctx, "chrome", "example.com");
    expect(addCookies).toHaveBeenCalled();
    const cookies = addCookies.mock.calls[0][0];
    // Converted: chromeEpoch / 1_000_000 - 11644473600
    expect(cookies[0].expires).toBe(chromeEpoch / 1000000 - 11644473600);
  });

  it("handles sqlite errors gracefully", async () => {
    const ctx = { addCookies: vi.fn() } as unknown as import("playwright").BrowserContext;
    mockExecSync.mockImplementation(() => { throw new Error("database locked"); });
    const result = await importCookies(ctx, "chrome");
    expect(result.count).toBe(0);
    expect(result.error).toContain("database locked");
  });
});
