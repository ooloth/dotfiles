---
name: uphold-invariants
description: Load relevant code quality reference files (architecture, testing, security, type design, etc.) and apply their invariants to the current task. ALWAYS invoke before designing, writing, or editing ANY code.
---

## Your task

1. Read `~/.claude/references/README.md` to understand the invariant framing and tier definitions
2. List `~/.claude/references/` to see all available reference files
3. Load all files that are relevant to the current task, including any language-specific file (e.g. `rust.md`, `python.md`) that matches the primary language(s) of the current repository
4. If you notice a gap in the available invariant guidance, feel free to mention what should be added (if no gap, say nothing)
5. Proactively apply the invariants
