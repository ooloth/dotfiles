/**
 * Notion Writing database utilities - BUN VERSION
 * Zod validates AND provides TypeScript types (single system)
 */

import type { BlockObjectRequest } from "@notionhq/client/build/src/api-endpoints.js";
import { Client } from "@notionhq/client";
import { z } from "zod";
import { markdownToBlocks } from "./blocks.ts";

const WRITING_DATA_SOURCE_ID = "c296db5b-d2f1-44d4-abc6-f9a05736b143";

// Zod schema validates API response AND generates TypeScript type
const NotionPageResponseSchema = z.object({
  url: z.string(),
});

export async function createWritingPage(
  notion: Client,
  title: string,
  content: string,
  slug: string,
  description: string,
): Promise<string> {
  const pageData = await notion.pages.create({
    parent: { data_source_id: WRITING_DATA_SOURCE_ID },
    properties: {
      Title: { title: [{ type: "text" as const, text: { content: title } }] },
      Status: { status: { name: "Claude Draft" } },
      Type: { select: { name: "how-to" } },
      Destination: { multi_select: [{ name: "blog" }] },
      Description: { rich_text: [{ type: "text" as const, text: { content: description } }] },
      Slug: { rich_text: [{ type: "text" as const, text: { content: slug } }] },
    },
    children: markdownToBlocks(content) as BlockObjectRequest[],
  });

  // Validate response - throws if invalid
  const page = NotionPageResponseSchema.parse(pageData);
  return page.url;
}
