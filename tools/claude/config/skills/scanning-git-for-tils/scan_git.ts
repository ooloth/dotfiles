#!/usr/bin/env bun
/**
 * Scan GitHub commit history for TIL-worthy commits - BUN VERSION
 *
 * Usage: bun run scan_git.bun.ts [days]
 *
 * Demonstrates Bun advantages:
 * - Inline npm dependencies (auto-install on first run)
 * - No deno.json needed
 * - No permission flags needed
 * - TypeScript type safety + Zod validation
 */

import { z } from "zod";
import { getCommits, getGitHubUsername } from "./git/commits.ts";
import { formatMarkdown, shouldSkipCommit } from "./git/formatting.ts";
import { getAssessedCommitsFromNotion } from "./notion/commits.ts";

const CommitSummarySchema = z.object({
  hash: z.string(),
  message: z.string(),
  repo: z.string(),
  date: z.string(),
});

const ScanGitOutputSchema = z.object({
  markdown: z.string(),
  new_commits: z.array(CommitSummarySchema),
});

type ScanGitOutput = z.infer<typeof ScanGitOutputSchema>;

async function main() {
  // Parse arguments
  const days = Bun.argv[2] ? parseInt(Bun.argv[2], 10) || 30 : 30;

  // Fetch assessed commits from Notion
  const assessedHashes = await getAssessedCommitsFromNotion();

  // Get GitHub username
  const username = await getGitHubUsername();
  if (!username) {
    console.log(
      JSON.stringify({
        error: "Could not get GitHub username. Is `gh` authenticated?",
        markdown: "",
        new_commits: [],
      }),
    );
    process.exit(1);
  }

  // Get commits
  const commits = await getCommits(days, username);
  const totalCount = commits.length;

  if (commits.length === 0) {
    const output: ScanGitOutput = {
      markdown: formatMarkdown([], days, 0, 0),
      new_commits: [],
    };
    console.log(JSON.stringify(output));
    process.exit(0);
  }

  // Filter out already assessed commits and skippable commits
  const newCommits = commits.filter((c) =>
    !assessedHashes.has(c.full_hash) && !shouldSkipCommit(c)
  );
  const newCount = newCommits.length;

  // Prepare output
  const output: ScanGitOutput = {
    markdown: formatMarkdown(newCommits, days, newCount, totalCount),
    new_commits: newCommits.map((c) => ({
      hash: c.full_hash,
      message: c.subject,
      repo: c.repo,
      date: c.iso_date,
    })),
  };

  console.log(JSON.stringify(output, null, 2));
}

main();
