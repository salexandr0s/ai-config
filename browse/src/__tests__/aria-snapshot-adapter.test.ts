import { describe, it, expect } from "vitest";
import { parseAriaSnapshot } from "../aria-snapshot-adapter.js";

describe("parseAriaSnapshot", () => {
  it("returns empty array for empty input", () => {
    expect(parseAriaSnapshot("")).toEqual([]);
    expect(parseAriaSnapshot("   \n  \n")).toEqual([]);
  });

  it("parses single element", () => {
    const result = parseAriaSnapshot('- button "Submit"');
    expect(result).toHaveLength(1);
    expect(result[0].role).toBe("button");
    expect(result[0].name).toBe("Submit");
    expect(result[0].ref).toBe("@b1");
  });

  it("parses nested structure", () => {
    const input = [
      '- document "Page":',
      '  - button "Click me"',
      '  - link "Home"',
    ].join("\n");

    const result = parseAriaSnapshot(input);
    expect(result).toHaveLength(1);
    expect(result[0].role).toBe("document");
    expect(result[0].children).toHaveLength(2);
    expect(result[0].children![0].role).toBe("button");
    expect(result[0].children![0].name).toBe("Click me");
    expect(result[0].children![1].role).toBe("link");
    expect(result[0].children![1].name).toBe("Home");
  });

  it("assigns correct ref prefixes", () => {
    const input = [
      '- link "A"',
      '- button "B"',
      '- textbox "C"',
      '- heading "D"',
    ].join("\n");

    const result = parseAriaSnapshot(input);
    expect(result[0].ref).toBe("@l1");
    expect(result[1].ref).toBe("@b2");
    expect(result[2].ref).toBe("@t3");
    expect(result[3].ref).toBe("@e4");
  });

  it("handles deeply nested trees", () => {
    const input = [
      '- document "Root":',
      '  - navigation "Nav":',
      '    - link "Home"',
      '    - link "About"',
      '  - main "Content":',
      '    - button "Submit"',
    ].join("\n");

    const result = parseAriaSnapshot(input);
    expect(result).toHaveLength(1);
    expect(result[0].children).toHaveLength(2);
    expect(result[0].children![0].children).toHaveLength(2);
    expect(result[0].children![1].children).toHaveLength(1);
  });

  it("handles elements without names", () => {
    const result = parseAriaSnapshot("- generic");
    expect(result).toHaveLength(1);
    expect(result[0].role).toBe("generic");
    expect(result[0].name).toBeUndefined();
  });

  it("handles multiple top-level elements", () => {
    const input = [
      '- button "A"',
      '- button "B"',
      '- button "C"',
    ].join("\n");

    const result = parseAriaSnapshot(input);
    expect(result).toHaveLength(3);
  });
});
