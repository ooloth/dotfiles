# scanning-git-for-tils

**TypeScript/Deno implementation for direct comparison with Python version.**

Scans GitHub commit history for commits worth turning into TIL (Today I Learned) blog posts, then helps draft and publish them to Notion.

## What This Skill Does

1. **Scans commits**: Fetches recent commits from all your GitHub repos via `gh` CLI
2. **Filters noise**: Skips merge commits, dependency bumps, and already-assessed commits
3. **Returns summaries**: Shows formatted commit list with repo, message, files, and URLs
4. **Tracks assessment**: Uses Notion database to remember which commits have been reviewed
5. **Publishes drafts**: Creates TIL pages in Notion Writing database with proper metadata

## Why TypeScript Version Exists

This is a **direct comparison** with the Python version at `scan-git-for-tils/`. Both implement identical functionality to demonstrate:

- **Type safety differences**: TypeScript discriminated unions vs Python TypedDict
- **Validation approaches**: Zod (single system) vs Pydantic + mypy (two systems)
- **Developer experience**: Deno's built-in tooling vs uv + ruff + mypy
- **Type narrowing**: How union types work in each language

See `README.md` for detailed comparison.

## Usage

### Scan for TIL opportunities

```bash
deno task scan [days]
```

**Input**: Number of days to look back (default: 30)

**Output**: JSON with:
- `markdown`: Formatted summary of commits for Claude to review
- `new_commits`: Array of commit metadata

### Publish a TIL

```bash
echo '<json>' | deno task publish
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
deno task test
```

Runs 18 tests covering:
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
type Response = z.infer<typeof schema>;  // Type from schema
const data = schema.parse(response);     // Runtime validation
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

Uses `gh` CLI via `Deno.Command`:

```typescript
const proc = new Deno.Command("gh", {
  args: ["api", "search/commits", ...],
  stdout: "piped",
});
const { stdout } = await proc.output();
```

### 1Password Integration

Fetches secrets via `op` CLI:

```typescript
export async function getOpSecret(path: string): Promise<string> {
  const proc = new Deno.Command("op", {
    args: ["read", path],
    stdout: "piped",
  });
  const { code, stdout } = await proc.output();
  return code === 0 ? new TextDecoder().decode(stdout).trim() : "";
}
```

## Dependencies

Managed in `deno.json`:
```json
{
  "imports": {
    "zod": "npm:zod@^3.22.4",
    "@notionhq/client": "npm:@notionhq/client@^2.2.15"
  }
}
```

No inline script metadata like Python/uv - config must be in separate file.

## File Structure

```
scanning-git-for-tils/
├── deno.json              # Dependencies and tasks
├── SKILL.md              # This file
├── README.md             # Comparison guide
├── scan_git.ts           # Main scanner
├── publish_til.ts        # Publishing script
├── test.ts               # Tests
├── git/
│   ├── commits.ts        # GitHub API integration
│   └── formatting.ts     # Commit filtering/formatting
├── notion/
│   ├── blocks.ts         # Markdown → Notion (discriminated unions!)
│   ├── commits.ts        # Tracker database management
│   └── writing.ts        # Writing database integration
└── op/
    └── secrets.ts        # 1Password integration
```

## Development Workflow

**Format code:**
```bash
deno fmt
```

**Lint code:**
```bash
deno lint
```

**Type check:**
```bash
deno check scan_git.ts
```

All three tools built into Deno - no separate dependencies needed.

## When to Use This Version

**Use TypeScript/Deno when:**
- Heavy API validation required
- Complex discriminated union types
- Type safety is critical
- You want single validation+typing system

**Use Python/uv version when:**
- Simple file/text processing
- Inline script feel is important
- No complex union types needed
- Quick one-offs

## Comparison to Python Version

See `README.md` for comprehensive comparison covering:
- Type system differences
- Validation approaches
- Development experience
- Dependency management
- When to use each language
