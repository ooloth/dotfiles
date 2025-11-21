/**
 * Tests for pure functions in TIL workflow TypeScript implementation.
 *
 * Run with: deno task test
 *
 * Compare to Python version - notice:
 * - No need for sys.path manipulation
 * - Deno's built-in test runner (no pytest)
 * - TypeScript types catch errors at compile time
 */

import { assertEquals, assertExists, assert } from "https://deno.land/std@0.208.0/assert/mod.ts";
import type { Commit } from "./git/commits.ts";
import { formatRelativeDate } from "./git/commits.ts";
import { formatMarkdown, shouldSkipCommit } from "./git/formatting.ts";
import { extractPageId, markdownToBlocks } from "./notion/blocks.ts";

// Test relative date formatting
Deno.test("formatRelativeDate - formats recent as hours or just now", () => {
  const now = new Date().toISOString();
  const result = formatRelativeDate(now);
  // Could be "just now" or "N hours ago" depending on timing
  assert(result.includes("ago") || result === "just now");
});

Deno.test("formatRelativeDate - formats yesterday", () => {
  const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const result = formatRelativeDate(yesterday);
  assertEquals(result, "yesterday");
});

Deno.test("formatRelativeDate - formats days ago", () => {
  const daysAgo = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString();
  const result = formatRelativeDate(daysAgo);
  assert(result.includes("ago"));
});

Deno.test("formatRelativeDate - handles invalid date", () => {
  const result = formatRelativeDate("not-a-date");
  assertEquals(result, "unknown");
});

Deno.test("formatRelativeDate - handles empty string", () => {
  const result = formatRelativeDate("");
  assertEquals(result, "unknown");
});

// Test commit filtering logic
Deno.test("shouldSkipCommit - skips dependabot commits", () => {
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
  assertEquals(shouldSkipCommit(commit), true);
});

Deno.test("shouldSkipCommit - skips bump commits", () => {
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
  assertEquals(shouldSkipCommit(commit), true);
});

Deno.test("shouldSkipCommit - skips merge commits", () => {
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
  assertEquals(shouldSkipCommit(commit), true);
});

Deno.test("shouldSkipCommit - keeps normal commits", () => {
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
  assertEquals(shouldSkipCommit(commit), false);
});

Deno.test("shouldSkipCommit - keeps feature commits", () => {
  const commit: Commit = {
    hash: "abc1234",
    full_hash: "abc123",
    subject: "feat: add new TIL workflow",
    body: "",
    date: "yesterday",
    iso_date: "2025-01-15",
    repo: "owner/repo",
    files: [],
    url: "https://github.com/owner/repo/commit/abc123",
  };
  assertEquals(shouldSkipCommit(commit), false);
});

// Test markdown formatting for commits
Deno.test("formatMarkdown - formats empty list", () => {
  const result = formatMarkdown([], 30, 0, 0);
  assert(result.includes("Git commits from last 30 days:"));
  assert(result.includes("No commits found"));
});

Deno.test("formatMarkdown - formats all already reviewed", () => {
  const result = formatMarkdown([], 30, 0, 5);
  assert(result.includes("Git commits from last 30 days:"));
  assert(result.includes("No new commits to assess"));
  assert(result.includes("5 commits already reviewed"));
});

Deno.test("formatMarkdown - formats single commit basic", () => {
  const commit: Commit = {
    hash: "abc1234",
    full_hash: "abc123456789",
    subject: "feat: add new feature",
    body: "",
    date: "2 days ago",
    iso_date: "2025-01-15",
    repo: "owner/repo",
    files: ["src/main.py"],
    url: "https://github.com/owner/repo/commit/abc123456789",
  };
  const result = formatMarkdown([commit], 30, 1, 1);

  assert(result.includes("Git commits from last 30 days:"));
  assert(result.includes("1. [owner/repo] feat: add new feature"));
  assert(result.includes("Hash: abc1234 (index: 0) | Date: 2 days ago"));
  assert(result.includes("Files: src/main.py"));
  assert(result.includes("URL: https://github.com/owner/repo/commit/abc123456789"));
});

Deno.test("formatMarkdown - formats commit with body", () => {
  const commit: Commit = {
    hash: "abc1234",
    full_hash: "abc123456789",
    subject: "fix: handle edge case",
    body: "This fixes an issue where null values weren't handled properly.",
    date: "yesterday",
    iso_date: "2025-01-15",
    repo: "owner/repo",
    files: ["src/handler.py"],
    url: "https://github.com/owner/repo/commit/abc123456789",
  };
  const result = formatMarkdown([commit], 30, 1, 1);

  assert(result.includes("Body: This fixes an issue where null values weren't handled properly."));
});

Deno.test("formatMarkdown - formats commit with long body", () => {
  const longBody = "a".repeat(250);
  const commit: Commit = {
    hash: "abc1234",
    full_hash: "abc123456789",
    subject: "feat: major refactor",
    body: longBody,
    date: "yesterday",
    iso_date: "2025-01-15",
    repo: "owner/repo",
    files: ["src/main.py"],
    url: "https://github.com/owner/repo/commit/abc123456789",
  };
  const result = formatMarkdown([commit], 30, 1, 1);

  assert(result.includes("Body: " + "a".repeat(200) + "..."));
  const bodyLine = result.split("\n").find((line) => line.includes("Body:"));
  assert(bodyLine && bodyLine.length < 220);
});

Deno.test("formatMarkdown - formats commit with no files", () => {
  const commit: Commit = {
    hash: "abc1234",
    full_hash: "abc123456789",
    subject: "chore: update docs",
    body: "",
    date: "yesterday",
    iso_date: "2025-01-15",
    repo: "owner/repo",
    files: [],
    url: "https://github.com/owner/repo/commit/abc123456789",
  };
  const result = formatMarkdown([commit], 30, 1, 1);

  assert(result.includes("Files: (no files)"));
});

Deno.test("formatMarkdown - formats commit with many files", () => {
  const files = Array.from({ length: 10 }, (_, i) => `file${i}.py`);
  const commit: Commit = {
    hash: "abc1234",
    full_hash: "abc123456789",
    subject: "refactor: reorganize code",
    body: "",
    date: "yesterday",
    iso_date: "2025-01-15",
    repo: "owner/repo",
    files,
    url: "https://github.com/owner/repo/commit/abc123456789",
  };
  const result = formatMarkdown([commit], 30, 1, 1);

  // Should show first 5 files
  assert(result.includes("file0.py, file1.py, file2.py, file3.py, file4.py"));
  // Should indicate there are more
  assert(result.includes("(+5 more)"));
  // Should NOT show file5 or later
  assert(!result.includes("file5.py"));
});

Deno.test("formatMarkdown - formats multiple commits", () => {
  const commits: Commit[] = [
    {
      hash: "abc1234",
      full_hash: "abc123",
      subject: "First commit",
      body: "",
      date: "2 days ago",
      iso_date: "2025-01-15",
      repo: "owner/repo1",
      files: ["a.py"],
      url: "https://github.com/owner/repo1/commit/abc123",
    },
    {
      hash: "def5678",
      full_hash: "def567",
      subject: "Second commit",
      body: "",
      date: "yesterday",
      iso_date: "2025-01-16",
      repo: "owner/repo2",
      files: ["b.py"],
      url: "https://github.com/owner/repo2/commit/def567",
    },
  ];
  const result = formatMarkdown(commits, 7, 2, 2);

  assert(result.includes("1. [owner/repo1] First commit"));
  assert(result.includes("Hash: abc1234 (index: 0)"));
  assert(result.includes("2. [owner/repo2] Second commit"));
  assert(result.includes("Hash: def5678 (index: 1)"));
});

Deno.test("formatMarkdown - shows review status when some already reviewed", () => {
  const commit: Commit = {
    hash: "abc1234",
    full_hash: "abc123",
    subject: "New commit",
    body: "",
    date: "yesterday",
    iso_date: "2025-01-15",
    repo: "owner/repo",
    files: ["a.py"],
    url: "https://github.com/owner/repo/commit/abc123",
  };
  const result = formatMarkdown([commit], 30, 1, 5);

  assert(result.includes("Git commits from last 30 days:"));
  assert(result.includes("(1 new, 4 already reviewed)"));
});

// Test Notion URL page ID extraction
Deno.test("extractPageId - extracts from standard URL", () => {
  const url = "https://www.notion.so/Page-Title-abc123def456";
  const result = extractPageId(url);
  assertEquals(result, "abc123def456");
});

Deno.test("extractPageId - extracts from URL with query params", () => {
  const url = "https://www.notion.so/Page-Title-abc123def456?v=xyz";
  const result = extractPageId(url);
  assertEquals(result, "abc123def456");
});

Deno.test("extractPageId - extracts from short URL", () => {
  const url = "https://notion.so/abc123def456";
  const result = extractPageId(url);
  assertEquals(result, "abc123def456");
});

Deno.test("extractPageId - handles trailing slash", () => {
  const url = "https://www.notion.so/Page-Title-abc123def456/";
  const result = extractPageId(url);
  assertEquals(result, "abc123def456");
});

Deno.test("extractPageId - handles empty string", () => {
  const result = extractPageId("");
  assertEquals(result, "");
});

// Test markdown to Notion blocks conversion
Deno.test("markdownToBlocks - converts code blocks", () => {
  const markdown = "```python\nprint('hello')\n```";
  const blocks = markdownToBlocks(markdown);

  assertEquals(blocks.length, 1);
  assertEquals(blocks[0].type, "code");

  // TypeScript narrows the type automatically
  if (blocks[0].type === "code") {
    assertEquals(blocks[0].code.language, "python");
    assertEquals(blocks[0].code.rich_text[0].text.content, "print('hello')");
  }
});

Deno.test("markdownToBlocks - maps language aliases", () => {
  const markdown = "```js\nconsole.log('test')\n```";
  const blocks = markdownToBlocks(markdown);

  if (blocks[0].type === "code") {
    assertEquals(blocks[0].code.language, "javascript");
  }
});

Deno.test("markdownToBlocks - converts headings", () => {
  const markdown = "# H1\n## H2\n### H3";
  const blocks = markdownToBlocks(markdown);

  assertEquals(blocks.length, 3);
  assertEquals(blocks[0].type, "heading_1");
  assertEquals(blocks[1].type, "heading_2");
  assertEquals(blocks[2].type, "heading_3");
});

Deno.test("markdownToBlocks - converts bullet lists", () => {
  const markdown = "- Item 1\n- Item 2";
  const blocks = markdownToBlocks(markdown);

  assertEquals(blocks.length, 2);
  assertEquals(blocks[0].type, "bulleted_list_item");

  if (blocks[0].type === "bulleted_list_item") {
    assertEquals(blocks[0].bulleted_list_item.rich_text[0].text.content, "Item 1");
  }
});

Deno.test("markdownToBlocks - converts numbered lists", () => {
  const markdown = "1. First\n2. Second";
  const blocks = markdownToBlocks(markdown);

  assertEquals(blocks.length, 2);
  assertEquals(blocks[0].type, "numbered_list_item");
  assertEquals(blocks[1].type, "numbered_list_item");
});

Deno.test("markdownToBlocks - converts paragraphs", () => {
  const markdown = "This is a paragraph";
  const blocks = markdownToBlocks(markdown);

  assertEquals(blocks.length, 1);
  assertEquals(blocks[0].type, "paragraph");

  if (blocks[0].type === "paragraph") {
    assertEquals(blocks[0].paragraph.rich_text[0].text.content, "This is a paragraph");
  }
});

Deno.test("markdownToBlocks - handles empty lines", () => {
  const markdown = "Line 1\n\nLine 2";
  const blocks = markdownToBlocks(markdown);

  assertEquals(blocks.length, 3);
  assertEquals(blocks[1].type, "paragraph");

  if (blocks[1].type === "paragraph") {
    assertEquals(blocks[1].paragraph.rich_text, []);
  }
});

Deno.test("markdownToBlocks - handles multiline code blocks", () => {
  const markdown = "```python\nline1\nline2\nline3\n```";
  const blocks = markdownToBlocks(markdown);

  assertEquals(blocks.length, 1);

  if (blocks[0].type === "code") {
    assertEquals(blocks[0].code.rich_text[0].text.content.includes("line1"), true);
    assertEquals(blocks[0].code.rich_text[0].text.content.includes("line2"), true);
    assertEquals(blocks[0].code.rich_text[0].text.content.includes("line3"), true);
  }
});
