/**
 * 1Password secret retrieval.
 */

export const OP_NOTION_TOKEN = "op://Scripts/Notion/api-access-token";

export async function getOpSecret(path: string): Promise<string> {
  const proc = new Deno.Command("op", {
    args: ["read", path],
    stdout: "piped",
    stderr: "piped",
  });

  const { code, stdout } = await proc.output();
  if (code !== 0) return "";

  return new TextDecoder().decode(stdout).trim();
}
