/**
 * Git commit formatting utilities.
 */

import type { Commit } from "./commits.ts";

export function shouldSkipCommit(commit: Commit): boolean {
  const subject = commit.subject.toLowerCase();

  // Skip dependabot commits
  if (subject.includes("bump") && subject.includes("from")) return true;

  // Skip merge commits
  if (subject.startsWith("merge")) return true;

  return false;
}

export function formatMarkdown(
  commits: Commit[],
  days: number,
  newCount: number,
  totalCount: number,
): string {
  const lines: string[] = [];

  // Header
  if (totalCount === 0) {
    lines.push(`# Git commits from last ${days} days:\n`);
    lines.push("No commits found.\n");
    return lines.join("\n");
  }

  if (newCount === 0) {
    lines.push(`# Git commits from last ${days} days:\n`);
    lines.push(
      `No new commits to assess (${totalCount} commits already reviewed).\n`,
    );
    return lines.join("\n");
  }

  const reviewedCount = totalCount - newCount;
  const statusSuffix = reviewedCount > 0
    ? ` (${newCount} new, ${reviewedCount} already reviewed)`
    : "";
  lines.push(`# Git commits from last ${days} days:${statusSuffix}\n`);

  // Format each commit
  commits.forEach((commit, index) => {
    lines.push(`${index + 1}. [${commit.repo}] ${commit.subject}`);
    lines.push(`   Hash: ${commit.hash} (index: ${index}) | Date: ${commit.date}`);

    if (commit.body) {
      const truncated = commit.body.length > 200 ? commit.body.slice(0, 200) + "..." : commit.body;
      lines.push(`   Body: ${truncated}`);
    }

    const fileDisplay = commit.files.length === 0
      ? "(no files)"
      : commit.files.length > 5
      ? `${commit.files.slice(0, 5).join(", ")} (+${commit.files.length - 5} more)`
      : commit.files.join(", ");
    lines.push(`   Files: ${fileDisplay}`);
    lines.push(`   URL: ${commit.url}\n`);
  });

  return lines.join("\n");
}
