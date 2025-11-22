# scanning-git-for-tils (TypeScript/Bun)

**TypeScript/Bun implementation demonstrating when to choose Bun over Python/uv for Claude Code skills.**

## Why Bun for This Skill

This skill is ideal for Bun because it's **API-heavy with complex validation**:
- GitHub API integration
- Notion API integration (discriminated union types)
- 1Password integration
- Markdown → Notion blocks conversion

### Key Advantages Over Python

1. **Discriminated Unions Work Automatically**
   ```typescript
   // TypeScript narrows automatically - no Literal types needed
   if (block.type === "code") {
     block.code.language; // ✅ Just works
   }
   ```

   vs Python:
   ```python
   # Need explicit Literal types and if narrowing doesn't always work
   if block["type"] == "code":
       block["code"]["language"]  # ❌ Still sees union in mypy
   ```

2. **One Tool for Validation AND Types**
   ```typescript
   // Zod handles both runtime validation AND TypeScript types
   const schema = z.object({ url: z.string() });
   type Response = z.infer<typeof schema>; // Type derived from validation
   const response = schema.parse(data); // Validates AND types
   ```

   vs Python:
   ```python
   # Need TWO separate systems
   class Response(BaseModel):  # Pydantic for validation
       url: str
   # Plus separate TypedDict/dataclass for static typing
   ```

3. **No type: ignore Comments**
   - TypeScript: 0 type ignore comments
   - Python version: Required for notion_client API calls

4. **Structural Typing**
   - No Protocol hacks needed for library types
   - Types compose naturally

### Development Experience

**Python + uv:**

- ✅ Inline script dependencies (PEP 723)
- ❌ Two type systems (Pydantic + mypy)
- ❌ Union narrowing issues
- ❌ `type: ignore` comments needed

**TypeScript + Bun:**

- ✅ Standard package.json (LSP-friendly)
- ✅ One type system (Zod + TypeScript)
- ✅ Discriminated unions work perfectly
- ✅ No type escapes needed
- ✅ No permission flags
- ✅ Built-in formatter and test runner
- ✅ Better npm compatibility

## Usage

**First time setup:**
```bash
bun install
```

**Run the skill:**
```bash
# Scan commits
bun run scan_git.ts [days]

# Publish TIL
echo '<json>' | bun run publish_til.ts

# Run tests
bun test test.ts
```

## When to Use Bun vs Python vs Deno

**Use TypeScript/Bun when:**

- ✅ Heavy API validation (external data schemas)
- ✅ Complex discriminated unions
- ✅ Type safety is critical
- ✅ Want single validation+typing system
- ✅ Need inline dependencies

**Use Python/uv when:**

- ✅ Simple file/text processing
- ✅ Data manipulation pipelines
- ✅ No complex union types
- ✅ Quick one-offs
- ✅ Rich data science ecosystem

**Avoid Deno for skills:**

- ❌ Requires separate config file (deno.json)
- ❌ Verbose permission flags (--allow-*)
- ❌ Unnecessary complexity for skills
- ⚠️ Use Bun instead for same type safety benefits

## File Structure

```
scanning-git-for-tils/
├── SKILL.md                  # Skill documentation
├── COMPARISON.md             # Python vs Bun vs Deno comparison
├── scan_git.ts               # Main scanner (Bun)
├── publish_til.ts            # Publishing script (Bun)
├── test.ts                   # Tests (Bun)
├── git/
│   ├── commits.ts            # GitHub API
│   └── formatting.ts         # Commit filtering/formatting
├── notion/
│   ├── blocks.ts             # Block conversion (discriminated unions!)
│   ├── commits.ts            # Tracker management
│   └── writing.ts            # Writing DB
└── op/
    └── secrets.ts            # 1Password integration
```

## Performance

Both versions are comparable. TypeScript compilation happens at runtime but is fast enough for skills.

## Recommendation

For THIS skill (API-heavy): **TypeScript/Bun is superior**

- No type gymnastics
- Single source of truth for validation + types
- Inline dependencies (like Python/uv)
- No permission flags hassle (unlike Deno)
- Cleaner, more maintainable code

For simpler skills: **Python/uv is still king**

- Best for file/text processing
- Faster to write
- Rich ecosystem for data manipulation
- Type issues don't matter as much

**Never use Deno for skills** - config overhead and permission flags add unnecessary complexity.
