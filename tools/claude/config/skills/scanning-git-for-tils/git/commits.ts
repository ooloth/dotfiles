/**
 * GitHub commit fetching utilities - BUN VERSION
 * Notice: Zod validates AND provides types, no dual system needed
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
  const proc = Bun.spawn(["gh", "api", "user", "--jq", ".login"], {
    stdout: "pipe",
    stderr: "pipe",
  });

  const exitCode = await proc.exited;
  if (exitCode !== 0) return "";

  const output = await new Response(proc.stdout).text();
  return output.trim();
}

async function getCommitFiles(repo: string, sha: string): Promise<string[]> {
  if (!sha) return [];

  const proc = Bun.spawn(
    ["gh", "api", `repos/${repo}/commits/${sha}`, "--jq", "[.files[].filename]"],
    {
      stdout: "pipe",
      stderr: "pipe",
    },
  );

  const exitCode = await proc.exited;
  if (exitCode !== 0) return [];

  try {
    const output = await new Response(proc.stdout).text();
    return JSON.parse(output);
  } catch {
    return [];
  }
}

export async function getCommits(days: number, username: string): Promise<Commit[]> {
  const sinceDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
  const since = sinceDate.toISOString().split("T")[0];

  const query = `author:${username} committer-date:>=${since} sort:committer-date-desc`;

  const proc = Bun.spawn(
    [
      "gh",
      "api",
      "--method",
      "GET",
      "search/commits",
      "-f",
      `q=${query}`,
      "--paginate",
      "--jq",
      ".items[]",
    ],
    {
      stdout: "pipe",
      stderr: "pipe",
    },
  );

  const exitCode = await proc.exited;
  if (exitCode !== 0) return [];

  try {
    const output = await new Response(proc.stdout).text();
    const lines = output.trim().split("\n").filter((line) => line);
    const items: Record<string, unknown>[] = lines.map((line) => JSON.parse(line));

    // Build commits without files first
    const commits: Commit[] = items.map((item: Record<string, unknown>) => {
      const commitData = (item.commit as Record<string, unknown>) || {};
      const repo = ((item.repository as Record<string, unknown>)?.full_name as string) ||
        "unknown";
      const commitDate = ((commitData.committer as Record<string, unknown>)?.date as string) ||
        "";
      const messageLines = ((commitData.message as string) || "").split("\n");

      return {
        hash: ((item.sha as string) || "").slice(0, 7),
        full_hash: (item.sha as string) || "",
        subject: messageLines[0] || "",
        body: messageLines.slice(1).join("\n").trim(),
        date: commitDate ? new Date(commitDate).toLocaleDateString() : "",
        iso_date: commitDate.split("T")[0] || "",
        repo,
        files: [],
        url: (item.html_url as string) || "",
      };
    });

    // Fetch files for each commit in parallel
    const commitsWithFiles = await Promise.all(
      commits.map(async (commit) => {
        const files = await getCommitFiles(commit.repo, commit.full_hash);
        return { ...commit, files };
      }),
    );

    return commitsWithFiles;
  } catch {
    return [];
  }
}
