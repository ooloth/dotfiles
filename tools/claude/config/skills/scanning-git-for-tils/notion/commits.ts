/**
 * Notion assessed commits tracking.
 * Compare to Python: No Protocol hacks, no type: ignore comments.
 */

import { Client } from "@notionhq/client";
import { z } from "zod";
import { getOpSecret, OP_NOTION_TOKEN } from "../op/secrets.ts";

const ASSESSED_COMMITS_DATA_SOURCE_ID = "cba80148-aeef-49c9-ba45-5157668b17b3";
const NOTION_ASSESSED_COMMITS_DB = "928fcd9e47a84f98824790ac5a6d37ca";

// Zod validates AND provides types - no separate validation needed
const NotionPageResponseSchema = z.object({
  url: z.string(),
  id: z.string().optional(),
});

const NotionDatabaseQueryResponseSchema = z.object({
  results: z.array(z.unknown()),
  has_more: z.boolean(),
  next_cursor: z.string().nullable(),
});

export async function getAssessedCommitsFromNotion(): Promise<Set<string>> {
  const token = await getOpSecret(OP_NOTION_TOKEN);
  if (!token) return new Set();

  try {
    const notion = new Client({ auth: token });
    const assessedHashes = new Set<string>();
    let startCursor: string | null = null;

    while (true) {
      const queryParams: any = { database_id: NOTION_ASSESSED_COMMITS_DB };
      if (startCursor) queryParams.start_cursor = startCursor;

      const responseData = await notion.databases.query(queryParams);
      const response = NotionDatabaseQueryResponseSchema.parse(responseData);

      // Extract commit hashes
      for (const page of response.results) {
        if (typeof page !== "object" || !page) continue;
        const props = (page as any).properties;
        if (!props) continue;

        const titleProp = props["Commit Hash"];
        if (!titleProp?.title) continue;

        const titleContent = titleProp.title;
        if (!Array.isArray(titleContent) || titleContent.length === 0) continue;

        const commitHash = titleContent[0]?.plain_text;
        if (typeof commitHash === "string" && commitHash) {
          assessedHashes.add(commitHash);
        }
      }

      if (!response.has_more) break;
      startCursor = response.next_cursor;
    }

    return assessedHashes;
  } catch {
    return new Set();
  }
}

export async function findExistingTrackerEntry(
  notion: Client,
  commitHash: string,
): Promise<string> {
  try {
    const responseData = await notion.databases.query({
      database_id: ASSESSED_COMMITS_DATA_SOURCE_ID,
      filter: { property: "Commit Hash", title: { equals: commitHash } },
    });

    const response = NotionDatabaseQueryResponseSchema.parse(responseData);
    if (response.results.length > 0) {
      const firstResult = response.results[0];
      if (typeof firstResult === "object" && firstResult && "id" in firstResult) {
        return String(firstResult.id);
      }
    }
  } catch {
    // Ignore errors
  }

  return "";
}

export async function updateTrackerEntry(
  notion: Client,
  pageId: string,
  writingPageId: string,
): Promise<string> {
  const pageData = await notion.pages.update({
    page_id: pageId,
    properties: {
      Writing: { relation: [{ id: writingPageId }] },
      Assessed: { date: { start: new Date().toISOString().slice(0, 10) } },
    },
  });

  const page = NotionPageResponseSchema.parse(pageData);
  return page.url;
}

export async function createTrackerEntry(
  notion: Client,
  commit: Record<string, string>,
  writingPageId: string,
): Promise<string> {
  const properties: any = {
    "Commit Hash": { title: [{ type: "text", text: { content: commit.hash } }] },
    Message: { rich_text: [{ type: "text", text: { content: commit.message.slice(0, 2000) } }] },
    Repo: { rich_text: [{ type: "text", text: { content: commit.repo } }] },
    Assessed: { date: { start: new Date().toISOString().slice(0, 10) } },
    Writing: { relation: [{ id: writingPageId }] },
  };

  if (commit.date) {
    properties["Commit Date"] = { date: { start: commit.date } };
  }

  const pageData = await notion.pages.create({
    parent: { database_id: ASSESSED_COMMITS_DATA_SOURCE_ID },
    properties,
  });

  const page = NotionPageResponseSchema.parse(pageData);
  return page.url;
}
