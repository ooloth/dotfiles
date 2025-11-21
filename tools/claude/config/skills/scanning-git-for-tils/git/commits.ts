/**
 * GitHub commit fetching utilities.
 * Notice: No Pydantic needed - Zod handles validation AND types.
 */

import { z } from "zod";

// Zod schema that validates AND provides TypeScript type
export const CommitSchema = z.object({
  hash: z.string(),
  full_hash: z.string(),
  subject: z.string(),
  body: z.string(),
  date: z.string(),
  iso_date: z.string(),
  repo: z.string(),
  files: z.array(z.string()),
  url: z.string(),
});

export type Commit = z.infer<typeof CommitSchema>;

export async function getGitHubUsername(): Promise<string> {
  const proc = new Deno.Command("gh", {
    args: ["api", "user", "--jq", ".login"],
    stdout: "piped",
    stderr: "piped",
  });

  const { code, stdout } = await proc.output();
  if (code !== 0) return "";

  return new TextDecoder().decode(stdout).trim();
}

async function getCommitFiles(repo: string, sha: string): Promise<string[]> {
  if (!sha) return [];

  const proc = new Deno.Command("gh", {
    args: ["api", `repos/${repo}/commits/${sha}`, "--jq", "[.files[].filename]"],
    stdout: "piped",
    stderr: "piped",
  });

  const { code, stdout } = await proc.output();
  if (code !== 0) return [];

  try {
    return JSON.parse(new TextDecoder().decode(stdout));
  } catch {
    return [];
  }
}

export function formatRelativeDate(dateStr: string): string {
  try {
    const date = new Date(dateStr);
    // Check if date is invalid
    if (isNaN(date.getTime())) {
      return "unknown";
    }

    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
      return diffHours === 0 ? "just now" : `${diffHours} hours ago`;
    } else if (diffDays === 1) {
      return "yesterday";
    } else {
      return `${diffDays} days ago`;
    }
  } catch {
    return "unknown";
  }
}

export async function getCommits(days: number, username: string): Promise<Commit[]> {
  const sinceDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();
  const query = `author:${username} committer-date:>=${sinceDate.slice(0, 10)}`;

  const proc = new Deno.Command("gh", {
    args: [
      "api",
      "search/commits",
      "-X",
      "GET",
      "-f",
      `q=${query}`,
      "-f",
      "sort=committer-date",
      "-f",
      "per_page=100",
      "--jq",
      ".items",
    ],
    stdout: "piped",
    stderr: "piped",
  });

  const { code, stdout } = await proc.output();
  if (code !== 0) return [];

  try {
    const items = JSON.parse(new TextDecoder().decode(stdout));

    // Build commits without files first
    const commits: Commit[] = items.map((item: Record<string, unknown>) => {
      const commitData = (item.commit as Record<string, unknown>) || {};
      const repo =
        ((item.repository as Record<string, unknown>)?.full_name as string) ||
        "unknown";
      const commitDate =
        ((commitData.committer as Record<string, unknown>)?.date as string) ||
        "";
      const messageLines =
        ((commitData.message as string) || "").split("\n");

      return {
        hash: ((item.sha as string) || "").slice(0, 7),
        full_hash: (item.sha as string) || "",
        subject: messageLines[0],
        body: messageLines.slice(1).join("\n").trim(),
        date: formatRelativeDate(commitDate),
        iso_date: commitDate.slice(0, 10),
        repo,
        files: [],
        url: (item.html_url as string) || "",
      };
    });

    // Fetch files in parallel (limit concurrency)
    await Promise.all(
      commits.map(async (commit) => {
        try {
          commit.files = await getCommitFiles(commit.repo, commit.full_hash);
        } catch {
          commit.files = [];
        }
      }),
    );

    return commits;
  } catch {
    return [];
  }
}
