/**
 * Tests for pure functions in TIL workflow - BUN VERSION
 *
 * Run with: bun test test.bun.ts
 *
 * Demonstrates Bun advantages:
 * - Built-in test runner (no pytest or Deno needed)
 * - TypeScript types catch errors at compile time
 * - No sys.path manipulation needed
 */

import { test, expect, describe } from "bun:test";
import type { Commit } from "./git/commits.ts";
import { formatMarkdown, shouldSkipCommit } from "./git/formatting.ts";
import { extractPageId, markdownToBlocks } from "./notion/blocks.ts";

// Test commit filtering logic
describe("shouldSkipCommit", () => {
  test("skips dependabot commits", () => {
    const commit: Commit = {
      hash: "abc1234",
      full_hash: "abc123",
      subject: "Bump dependency from 1.0 to 2.0",
      body: "",
      date: "yesterday",
      iso_date: "2025-01-15",
      repo: "owner/repo",
      files: [],
      url: "https://github.com/owner/repo/commit/abc123",
    };
    expect(shouldSkipCommit(commit)).toBe(true);
  });

  test("skips bump commits", () => {
    const commit: Commit = {
      hash: "abc1234",
      full_hash: "abc123",
      subject: "bump version from 1.0 to 2.0",
      body: "",
      date: "yesterday",
      iso_date: "2025-01-15",
      repo: "owner/repo",
      files: [],
      url: "https://github.com/owner/repo/commit/abc123",
    };
    expect(shouldSkipCommit(commit)).toBe(true);
  });

  test("skips merge commits", () => {
    const commit: Commit = {
      hash: "abc1234",
      full_hash: "abc123",
      subject: "merge pull request #123",
      body: "",
      date: "yesterday",
      iso_date: "2025-01-15",
      repo: "owner/repo",
      files: [],
      url: "https://github.com/owner/repo/commit/abc123",
    };
    expect(shouldSkipCommit(commit)).toBe(true);
  });

  test("keeps normal commits", () => {
    const commit: Commit = {
      hash: "abc1234",
      full_hash: "abc123",
      subject: "fix: handle null values properly",
      body: "",
      date: "yesterday",
      iso_date: "2025-01-15",
      repo: "owner/repo",
      files: [],
      url: "https://github.com/owner/repo/commit/abc123",
    };
    expect(shouldSkipCommit(commit)).toBe(false);
  });
});

// Test markdown formatting
describe("formatMarkdown", () => {
  test("formats empty list correctly", () => {
    const result = formatMarkdown([], 30, 0, 0);
    expect(result).toContain("No commits found");
  });

  test("formats single commit", () => {
    const commits: Commit[] = [
      {
        hash: "abc1234",
        full_hash: "abc123def456",
        subject: "fix: bug in parser",
        body: "Details about the fix",
        date: "2 days ago",
        iso_date: "2025-01-15",
        repo: "owner/repo",
        files: ["src/parser.ts"],
        url: "https://github.com/owner/repo/commit/abc123def456",
      },
    ];
    const result = formatMarkdown(commits, 30, 1, 1);
    expect(result).toContain("owner/repo");
    expect(result).toContain("fix: bug in parser");
    expect(result).toContain("abc1234");
  });
});

// Test page ID extraction
describe("extractPageId", () => {
  test("extracts ID from standard Notion URL", () => {
    const url = "https://www.notion.so/Page-Title-abc123def456";
    const id = extractPageId(url);
    expect(id).toBe("abc123def456");
  });

  test("extracts ID from URL with query params", () => {
    const url = "https://www.notion.so/Page-abc123?v=def456";
    const id = extractPageId(url);
    expect(id).toBe("abc123");
  });

  test("handles empty URL", () => {
    const id = extractPageId("");
    expect(id).toBe("");
  });
});

// Test markdown to Notion blocks conversion
describe("markdownToBlocks", () => {
  test("converts heading", () => {
    const blocks = markdownToBlocks("# Heading 1");
    expect(blocks.length).toBe(1);
    expect(blocks[0].type).toBe("heading_1");
    if (blocks[0].type === "heading_1") {
      expect(blocks[0].heading_1.rich_text[0].text.content).toBe("Heading 1");
    }
  });

  test("converts paragraph", () => {
    const blocks = markdownToBlocks("This is a paragraph");
    expect(blocks.length).toBe(1);
    expect(blocks[0].type).toBe("paragraph");
    if (blocks[0].type === "paragraph") {
      expect(blocks[0].paragraph.rich_text[0].text.content).toBe("This is a paragraph");
    }
  });

  test("converts code block", () => {
    const markdown = "```typescript\nconst x = 1;\n```";
    const blocks = markdownToBlocks(markdown);
    expect(blocks.length).toBe(1);
    expect(blocks[0].type).toBe("code");
    if (blocks[0].type === "code") {
      expect(blocks[0].code.language).toBe("typescript");
      expect(blocks[0].code.rich_text[0].text.content).toBe("const x = 1;");
    }
  });

  test("converts bulleted list", () => {
    const markdown = "- Item 1\n- Item 2";
    const blocks = markdownToBlocks(markdown);
    expect(blocks.length).toBe(2);
    expect(blocks[0].type).toBe("bulleted_list_item");
    expect(blocks[1].type).toBe("bulleted_list_item");
  });

  test("converts numbered list", () => {
    const markdown = "1. First\n2. Second";
    const blocks = markdownToBlocks(markdown);
    expect(blocks.length).toBe(2);
    expect(blocks[0].type).toBe("numbered_list_item");
    expect(blocks[1].type).toBe("numbered_list_item");
  });

  test("handles empty lines", () => {
    const markdown = "Paragraph 1\n\nParagraph 2";
    const blocks = markdownToBlocks(markdown);
    expect(blocks.length).toBe(3);
    expect(blocks[0].type).toBe("paragraph");
    expect(blocks[1].type).toBe("paragraph"); // Empty paragraph
    expect(blocks[2].type).toBe("paragraph");
  });

  test("handles mixed content", () => {
    const markdown = "# Title\n\nSome text\n\n```js\ncode();\n```\n\n- List item";
    const blocks = markdownToBlocks(markdown);
    expect(blocks.length).toBe(5);
    expect(blocks[0].type).toBe("heading_1");
    expect(blocks[1].type).toBe("paragraph"); // Empty line
    expect(blocks[2].type).toBe("paragraph"); // "Some text"
    expect(blocks[3].type).toBe("code");
    expect(blocks[4].type).toBe("bulleted_list_item");
  });
});
