# scanning-git-for-tils

**TypeScript/Bun implementation - preferred for API-heavy skills with complex validation.**

Scans GitHub commit history for commits worth turning into TIL (Today I Learned) blog posts, then helps draft and publish them to Notion.

## What This Skill Does

1. **Scans commits**: Fetches recent commits from all your GitHub repos via `gh` CLI
2. **Filters noise**: Skips merge commits, dependency bumps, and already-assessed commits
3. **Returns summaries**: Shows formatted commit list with repo, message, files, and URLs
4. **Tracks assessment**: Uses Notion database to remember which commits have been reviewed
5. **Publishes drafts**: Creates TIL pages in Notion Writing database with proper metadata

## Why TypeScript/Bun Version

This skill demonstrates when to choose TypeScript/Bun over Python/uv:

- **Type safety**: TypeScript discriminated unions work automatically (vs Python's limited narrowing)
- **Single validation system**: Zod validates AND provides types (vs Pydantic + mypy dual system)
- **Inline dependencies**: Auto-install like Python's PEP 723 (no config files needed)
- **Better npm integration**: Official @notionhq/client SDK (vs unofficial Python library)
- **No permission flags**: Unlike Deno, Bun runs without verbose `--allow-*` flags

See `COMPARISON.md` for detailed Python/Bun/Deno comparison.

## Usage

### Scan for TIL opportunities

```bash
bun run scan_git.ts [days]
```

**Input**: Number of days to look back (default: 30)

**Output**: JSON with:

- `markdown`: Formatted summary of commits for Claude to review
- `new_commits`: Array of commit metadata

### Publish a TIL

```bash
echo '<json>' | bun run publish_til.ts
```

**Input** (JSON via stdin):

```json
{
  "title": "TIL: How TypeScript discriminated unions work",
  "content": "# TypeScript Discriminated Unions\n\n...",
  "slug": "typescript-discriminated-unions",
  "description": "Understanding how TypeScript narrows union types",
  "commit": {
    "hash": "abc123def456",
    "message": "feat: add discriminated union examples",
    "repo": "ooloth/dotfiles",
    "date": "2025-01-15"
  }
}
```

**Output**: JSON with:

- `writing_url`: Link to created Notion page
- `tracker_url`: Link to updated tracker entry

### Run tests

```bash
bun test test.ts
```

Runs tests covering:

- Commit filtering logic
- Markdown to Notion blocks conversion
- Page ID extraction from URLs

## Key Implementation Details

### Type Safety Wins

**Discriminated unions work automatically:**

```typescript
if (block.type === "code") {
  // TypeScript knows block.code exists - no casting needed
  const language = block.code.language;
}
```

**Zod validates AND types:**

```typescript
const schema = z.object({ url: z.string() });
type Response = z.infer<typeof schema>; // Type from schema
const data = schema.parse(response); // Runtime validation
```

**No type escapes needed:**

- Zero `any` types
- Zero `cast()` calls
- Zero `type: ignore` comments

### Notion API Integration

Uses `@notionhq/client` with Zod validation:

```typescript
const response = await notion.databases.query({ ... });
const validated = ResponseSchema.parse(response);
```

TypeScript's structural typing means no Protocol hacks needed.

### GitHub API Integration

Uses `gh` CLI via `Bun.spawn`:

```typescript
const proc = Bun.spawn(["gh", "api", "search/commits", ...], {
  stdout: "pipe",
});
const exitCode = await proc.exited;
const output = await new Response(proc.stdout).text();
```

### 1Password Integration

Fetches secrets via `op` CLI:

```typescript
export async function getOpSecret(path: string): Promise<string> {
  const proc = Bun.spawn(["op", "read", path], {
    stdout: "pipe",
  });
  const exitCode = await proc.exited;
  if (exitCode !== 0) return "";

  const output = await new Response(proc.stdout).text();
  return output.trim();
}
```

## Dependencies

**Auto-installed via inline imports** (like Python/uv's PEP 723):

```typescript
import { z } from "zod@^3.22.4";
import { Client } from "@notionhq/client@^2.2.15";
```

No config file needed - Bun auto-installs on first run and caches for subsequent runs.

## File Structure

```
scanning-git-for-tils/
├── SKILL.md                  # This file
├── COMPARISON.md             # Python vs Bun vs Deno comparison
├── scan_git.ts               # Main scanner (Bun)
├── publish_til.ts            # Publishing script (Bun)
├── test.ts                   # Tests (Bun)
├── git/
│   ├── commits.ts            # GitHub API integration
│   └── formatting.ts         # Commit filtering/formatting
├── notion/
│   ├── blocks.ts             # Markdown → Notion (discriminated unions!)
│   ├── commits.ts            # Tracker database management
│   └── writing.ts            # Writing database integration
└── op/
    └── secrets.ts            # 1Password integration
```

## Development Workflow

**Format code:**

```bash
bun fmt
# Or use Prettier/Biome
```

**Type check:**

```bash
bun run --bun scan_git.ts --check
# Or use tsc
```

**Run tests:**

```bash
bun test test.ts
```

Built-in formatter and test runner - no separate dependencies needed.

## When to Use Bun vs Python

**Use TypeScript/Bun when:**

- ✅ Heavy API validation required
- ✅ Complex discriminated union types
- ✅ Type safety is critical
- ✅ Working with npm ecosystem
- ✅ Single validation+typing system needed

**Use Python/uv when:**

- ✅ Simple file/text processing
- ✅ Data manipulation pipelines
- ✅ No complex union types needed
- ✅ Quick one-offs
- ✅ Rich data science ecosystem

**Avoid Deno for skills:**
- ❌ Requires config file (deno.json)
- ❌ Verbose permission flags (--allow-*)
- ❌ Unnecessary complexity for skills

See `COMPARISON.md` for detailed analysis.
