/**
 * Notion assessed commits tracking - BUN VERSION
 * Notice: No Protocol hacks, no type: ignore comments
 */

import { Client } from '@notionhq/client'
import { z } from 'zod'
import { getOpSecret, OP_NOTION_TOKEN } from '../op/secrets'

const ASSESSED_COMMITS_DATA_SOURCE_ID = 'cba80148-aeef-49c9-ba45-5157668b17b3'

// Zod validates AND provides types - no separate validation needed
const NotionPageResponseSchema = z.object({
  url: z.string(),
  id: z.string().optional(),
})

const NotionDatabaseQueryResponseSchema = z.object({
  results: z.array(z.unknown()),
  has_more: z.boolean(),
  next_cursor: z.string().nullable(),
})

export async function getAssessedCommitsFromNotion(): Promise<Set<string>> {
  const token = await getOpSecret(OP_NOTION_TOKEN)
  if (!token) return new Set()

  try {
    const notion = new Client({ auth: token, notionVersion: '2025-09-03' })
    const assessedHashes = new Set<string>()

    // Use collectPaginatedAPI to handle pagination automatically
    const pages = await notion.collectPaginatedAPI(notion.dataSources.query, {
      data_source_id: ASSESSED_COMMITS_DATA_SOURCE_ID,
    })

    // Extract commit hashes
    for (const page of pages) {
      if (typeof page !== 'object' || !page) continue
      const props = (page as Record<string, Record<string, unknown>>).properties
      if (!props || typeof props !== 'object') continue

      const titleProp = props['Commit Hash'] as { title?: unknown[] }
      if (!titleProp?.title) continue

      const titleContent = titleProp.title
      if (!Array.isArray(titleContent) || titleContent.length === 0) continue

      const commitHash = (titleContent[0] as { plain_text?: string })?.plain_text
      if (typeof commitHash === 'string' && commitHash) {
        assessedHashes.add(commitHash)
      }
    }

    return assessedHashes
  } catch {
    return new Set()
  }
}

export async function findExistingTrackerEntry(notion: Client, commitHash: string): Promise<string> {
  try {
    const responseData = await notion.dataSources.query({
      data_source_id: ASSESSED_COMMITS_DATA_SOURCE_ID,
      filter: { property: 'Commit Hash', title: { equals: commitHash } },
    })

    const response = NotionDatabaseQueryResponseSchema.parse(responseData)
    if (response.results.length > 0) {
      const firstResult = response.results[0]
      if (typeof firstResult === 'object' && firstResult && 'id' in firstResult) {
        return String(firstResult.id)
      }
    }
  } catch {
    // Ignore errors
  }

  return ''
}

export async function updateTrackerEntry(notion: Client, pageId: string, writingPageId: string): Promise<string> {
  const pageData = await notion.pages.update({
    page_id: pageId,
    properties: {
      Writing: { relation: [{ id: writingPageId }] },
      Assessed: { date: { start: new Date().toISOString().slice(0, 10) } },
    },
  })

  const page = NotionPageResponseSchema.parse(pageData)
  return page.url
}

export async function createTrackerEntry(
  notion: Client,
  commit: Record<string, string>,
  writingPageId: string,
): Promise<string> {
  const properties = {
    'Commit Hash': { title: [{ type: 'text' as const, text: { content: commit.hash } }] },
    Message: {
      rich_text: [{ type: 'text' as const, text: { content: commit.message.slice(0, 2000) } }],
    },
    Repo: { rich_text: [{ type: 'text' as const, text: { content: commit.repo } }] },
    Assessed: { date: { start: new Date().toISOString().slice(0, 10) } },
    Writing: { relation: [{ id: writingPageId }] },
    ...(commit.date && { 'Commit Date': { date: { start: commit.date } } }),
  }

  const pageData = await notion.pages.create({
    parent: { data_source_id: ASSESSED_COMMITS_DATA_SOURCE_ID },
    properties,
  })

  const page = NotionPageResponseSchema.parse(pageData)
  return page.url
}
