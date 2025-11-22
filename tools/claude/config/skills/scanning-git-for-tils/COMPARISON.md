# Implementation Comparison: Python/uv vs Deno vs Bun

Direct comparison of the same Claude Code skill implemented three ways.

## Side-by-Side: Inline Dependencies

### Python/uv ✅ Best for inline metadata
```python
#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["notion-client", "pydantic"]
# ///

from notion_client import Client  # type: ignore[attr-defined]
```

**Run:** `uv run scan_git.py 30`

### Bun ✅ Best for inline imports
```typescript
#!/usr/bin/env bun
import { Client } from "@notionhq/client@^2.2.15";
import { z } from "zod@^3.22.4";

// No config file needed!
```

**Run:** `bun run scan_git.bun.ts 30`
**First run:** Auto-installs dependencies
**Subsequent runs:** Uses cached deps

### Deno ❌ Requires config file
```typescript
// Requires deno.json:
// { "imports": { "zod": "npm:zod@^3.22.4", ... } }

import { z } from "zod";
```

**Run:** `deno run --allow-net --allow-env --allow-run scan_git.ts 30`

## Type Safety Comparison

### Discriminated Union Example

**TypeScript (Bun/Deno) ✅ Just works:**
```typescript
type CodeBlock = { type: "code"; code: { language: string } };
type Paragraph = { type: "paragraph"; paragraph: { text: string } };
type Block = CodeBlock | Paragraph;

function process(block: Block) {
  if (block.type === "code") {
    // TypeScript KNOWS block.code exists - automatic narrowing
    console.log(block.code.language);
  }
}
```

**Python ❌ Requires workarounds:**
```python
from typing import Literal, TypedDict, Union

class CodeBlock(TypedDict):
    type: Literal["code"]
    code: dict[str, str]

class Paragraph(TypedDict):
    type: Literal["paragraph"]
    paragraph: dict[str, str]

Block = Union[CodeBlock, Paragraph]

def process(block: Block) -> None:
    if block["type"] == "code":
        # mypy still sees Union type - narrowing doesn't work reliably
        print(block["code"]["language"])  # type: ignore
```

### Validation + Types

**Bun/Deno with Zod ✅ Single system:**
```typescript
import { z } from "zod@^3.22.4";

const schema = z.object({ url: z.string() });
type Response = z.infer<typeof schema>;  // Type from schema
const data = schema.parse(response);      // Runtime validation
```

**Python ❌ Dual systems:**
```python
from pydantic import BaseModel

# Pydantic for runtime validation
class Response(BaseModel):
    url: str

# Still need separate TypedDict for static typing in some cases
# Results in two sources of truth
```

## Process Spawning

### Bun ✅ Clean API
```typescript
const proc = Bun.spawn(["gh", "api", "user"], {
  stdout: "pipe",
  stderr: "pipe",
});

const exitCode = await proc.exited;
const output = await new Response(proc.stdout).text();
```

### Deno ⚠️ Verbose
```typescript
const proc = new Deno.Command("gh", {
  args: ["api", "user"],
  stdout: "piped",
  stderr: "piped",
});

const { code, stdout } = await proc.output();
const output = new TextDecoder().decode(stdout);
```

### Python/uv ✅ Simple
```python
result = subprocess.run(
    ["gh", "api", "user"],
    capture_output=True,
    text=True,
)
```

## Developer Experience

| Feature | Python/uv | Deno | Bun |
|---------|-----------|------|-----|
| **Inline dependencies** | ✅ PEP 723 | ❌ Needs deno.json | ✅ Auto-install |
| **Single file scripts** | ✅ Perfect | ❌ + config | ✅ Perfect |
| **Type safety** | ❌ Dual systems | ✅ Excellent | ✅ Excellent |
| **Union narrowing** | ❌ Limited | ✅ Automatic | ✅ Automatic |
| **Permission model** | N/A | ❌ Verbose flags | ✅ Frictionless |
| **npm compatibility** | N/A | ⚠️ Good | ✅ Excellent |
| **Built-in formatter** | ruff | ✅ `deno fmt` | ✅ `bun fmt` |
| **Built-in linter** | ruff | ✅ `deno lint` | ❌ Need separate |
| **Built-in test runner** | pytest | ✅ `deno test` | ✅ `bun test` |
| **Type escapes needed** | ✅ Many | ❌ Zero | ❌ Zero |
| **Ecosystem maturity** | ✅ Decades | ⚠️ Growing | ⚠️ Young |
| **Startup speed** | Fast | Fast | ✅ Fastest |

## Code Stats

| Metric | Python | Deno | Bun |
|--------|--------|------|-----|
| **Total lines** | 1,382 | 1,225 | 1,225 |
| **Main script** | 111 | 88 | 88 |
| **Test lines** | 503 | 407 | 407 |
| **Type escapes** | ~8 | 0 | 0 |

## When to Use Each

### Use Bun when:
- ✅ API-heavy validation (external data schemas)
- ✅ Complex discriminated unions needed
- ✅ Type safety is critical
- ✅ Want inline dependencies + TypeScript
- ✅ npm ecosystem compatibility matters
- ⚠️ Accept slightly younger runtime

### Use Python/uv when:
- ✅ Simple file/text processing
- ✅ Data manipulation pipelines
- ✅ Rich data science ecosystem needed
- ✅ Quick prototyping
- ✅ Type issues don't matter much
- ⚠️ Can accept type system limitations

### Use Deno when:
- ⚠️ Security sandboxing required
- ⚠️ Don't mind config files + permission flags
- ❌ Generally: Bun is better for skills

## Real-World Example: This Skill

**Complexity:**
- GitHub API integration (gh CLI)
- Notion API integration (@notionhq/client)
- 1Password integration (op CLI)
- Markdown → Notion blocks conversion
- Complex union types for Notion blocks

**Winner: Bun**

Why:
1. Inline dependencies = single-file feel
2. Zod + TypeScript = no type gymnastics
3. No permission flags hassle
4. Better npm package compatibility
5. Same type safety as Deno, easier DX

## Migration Strategy

**Recommendation:** Hybrid approach

1. **New API-heavy skills** → Start with Bun
2. **Existing Python skills** → Only migrate if type pain is real
3. **Simple text processing** → Keep using Python/uv
4. **Deno skills** → Consider migrating to Bun

**Template hierarchy:**
1. Does it process external API data with complex types? → Bun
2. Is it simple file/text manipulation? → Python/uv
3. Existing and works fine? → Don't touch it

## Conclusion

**For Claude Code skills specifically:**

- **Bun wins** for API-heavy work requiring type safety
- **Python/uv wins** for simple, data-focused tasks
- **Deno loses** due to config overhead + permission verbosity

The inline dependency feature in both Python (PEP 723) and Bun (auto-install) is crucial for skills - it keeps them self-contained and easy to understand.
