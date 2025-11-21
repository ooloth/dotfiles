# scanning-git-for-tils (TypeScript/Deno)

**This is a TypeScript/Deno rewrite of `scan-git-for-tils` for direct comparison.**

## Key Differences from Python Version

### Type System Wins

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

- ✅ Inline script dependencies (unbeatable)
- ❌ Two type systems (Pydantic + mypy)
- ❌ Union narrowing issues
- ❌ type: ignore comments

**TypeScript + Deno:**

- ✅ One type system (Zod + TypeScript)
- ✅ Discriminated unions work perfectly
- ✅ No type escapes needed
- ⚠️ Need deno.json (not inline like uv)
- ✅ Built-in formatter, linter, test runner
- ✅ Secure by default (explicit permissions)

## Usage

```bash
# Scan commits
deno task scan [days]

# Publish TIL
echo '<json>' | deno task publish

# Run tests
deno task test

# Format code
deno fmt

# Lint code
deno lint
```

## When to Use TypeScript vs Python

**Use TypeScript/Deno when:**

- Heavy API validation (external data schemas)
- Complex discriminated unions
- Type safety is critical
- Want single validation+typing system

**Use Python/uv when:**

- Simple file/text processing
- Inline script feel is important
- No complex union types
- Quick one-offs

## File Structure

```
scanning-git-for-tils/
├── deno.json              # Dependencies and tasks
├── scan_git.ts            # Main scanner
├── publish_til.ts         # Publishing script
├── git/
│   ├── commits.ts         # GitHub API
│   └── formatting.ts      # Commit filtering/formatting
├── notion/
│   ├── blocks.ts          # Block conversion (discriminated unions!)
│   ├── commits.ts         # Tracker management
│   └── writing.ts         # Writing DB
├── op/
│   └── secrets.ts         # 1Password integration
└── test.ts                # Tests
```

## Performance

Both versions are comparable. TypeScript compilation happens at runtime but is fast enough for skills.

## Recommendation

For THIS skill (API-heavy): **TypeScript/Deno is superior**

- No type gymnastics
- Single source of truth for validation + types
- Cleaner, more maintainable code

For simpler skills: **Python/uv is still king**

- Inline dependencies
- Faster to write
- Type issues don't matter as much
