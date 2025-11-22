/**
 * 1Password secret retrieval - BUN VERSION
 */

export const OP_NOTION_TOKEN = "op://Scripts/Notion/api-access-token";

export async function getOpSecret(path: string): Promise<string> {
  const proc = Bun.spawn(["op", "read", path], {
    stdout: "pipe",
    stderr: "pipe",
  });

  const exitCode = await proc.exited;
  if (exitCode !== 0) return "";

  const output = await new Response(proc.stdout).text();
  return output.trim();
}
