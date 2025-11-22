#!/usr/bin/env bun
/**
 * Publish a TIL draft to Notion and update the tracker - BUN VERSION
 *
 * Usage: echo '<json>' | bun run publish_til.bun.ts
 *
 * Input (JSON via stdin):
 * {
 *   "title": "TIL Title",
 *   "content": "Markdown content",
 *   "slug": "til-slug",
 *   "description": "One-line summary",
 *   "commit": {
 *     "hash": "full-sha-hash",
 *     "message": "commit message",
 *     "repo": "owner/repo",
 *     "date": "2025-01-15"
 *   }
 * }
 *
 * Demonstrates Bun advantages:
 * - Inline npm dependencies (auto-install on first run)
 * - Zod validates AND provides types (no separate Pydantic + typing)
 * - No type escapes needed
 * - Discriminated unions work automatically
 */

import { Client } from "@notionhq/client";
import { z } from "zod";
import { getOpSecret, OP_NOTION_TOKEN } from "./op/secrets.ts";
import { extractPageId } from "./notion/blocks.ts";
import {
  createTrackerEntry,
  findExistingTrackerEntry,
  updateTrackerEntry,
} from "./notion/commits.ts";
import { createWritingPage } from "./notion/writing.ts";

// Zod schemas validate AND provide TypeScript types
const CommitInputSchema = z.object({
  hash: z.string().min(1),
  message: z.string().min(1),
  repo: z.string().min(1),
  date: z.string().optional(),
});

const PublishTilInputSchema = z.object({
  title: z.string().min(1).max(2000),
  content: z.string().min(1),
  slug: z.string().min(1),
  description: z.string().min(1).max(2000),
  commit: CommitInputSchema,
});

const PublishTilOutputSchema = z.object({
  writing_url: z.string(),
  tracker_url: z.string(),
});

type PublishTilInput = z.infer<typeof PublishTilInputSchema>;
type PublishTilOutput = z.infer<typeof PublishTilOutputSchema>;

async function main() {
  // Read and validate JSON input from stdin
  let inputData: PublishTilInput;
  try {
    const stdinText = await Bun.stdin.text();
    const rawInput = JSON.parse(stdinText);
    inputData = PublishTilInputSchema.parse(rawInput);
  } catch (e) {
    console.log(JSON.stringify({ error: `Invalid input: ${e}` }));
    process.exit(1);
  }

  try {
    // Get Notion token
    const token = await getOpSecret(OP_NOTION_TOKEN);
    if (!token) {
      console.log(JSON.stringify({ error: "Could not get Notion token" }));
      process.exit(1);
    }

    // Create Notion client
    const notion = new Client({ auth: token });

    // Create Writing page
    const writingUrl = await createWritingPage(
      notion,
      inputData.title,
      inputData.content,
      inputData.slug,
      inputData.description,
    );

    if (!writingUrl) {
      console.log(JSON.stringify({ error: "Failed to create Writing page" }));
      process.exit(1);
    }

    // Extract page ID for relation
    const writingPageId = extractPageId(writingUrl);

    // Check if tracker entry already exists
    const existingTrackerId = await findExistingTrackerEntry(notion, inputData.commit.hash);

    let trackerUrl: string;
    if (existingTrackerId) {
      // Update existing entry with Writing relation
      trackerUrl = await updateTrackerEntry(notion, existingTrackerId, writingPageId);
    } else {
      // Create new tracker entry with relation to Writing page
      const commitDict: Record<string, string> = {
        hash: inputData.commit.hash,
        message: inputData.commit.message,
        repo: inputData.commit.repo,
        ...(inputData.commit.date && { date: inputData.commit.date }),
      };
      trackerUrl = await createTrackerEntry(notion, commitDict, writingPageId);
    }

    // Output results
    const output: PublishTilOutput = {
      writing_url: writingUrl,
      tracker_url: trackerUrl,
    };
    console.log(JSON.stringify(output, null, 2));
  } catch (e) {
    console.log(JSON.stringify({ error: String(e) }));
    process.exit(1);
  }
}

main();
