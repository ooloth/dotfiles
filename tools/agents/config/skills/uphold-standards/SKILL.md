---
name: uphold-standards
description: Load relevant code quality standards (architecture, testing, security, type design, etc.) and apply them to the current task. ALWAYS invoke before ANY technical decision, design, or code change — including architecture decisions made before any code exists.
---

## Your task

1. Read `~/.agents/standards/README.md` to understand the framing and tier definitions
2. List `~/.agents/standards/` to see all available standards files
3. Load all files that are relevant to the current task. **Match on the subject of the task, not on
   which files it touches** — the scope lines describe where a standard usually shows up, which is
   unhelpful when nothing has been written yet. A decision about what gets stored is in scope for
   `data-integrity.md` before any schema exists; a plan for how failures surface is in scope for
   `observability.md` before any code does. Include any language-specific file (e.g. `rust.md`,
   `python.md`) that matches the primary language(s) of the current repository.
4. If you notice a gap in the available guidance, feel free to mention what should be added (if no
   gap, say nothing)
5. Proactively apply the standards
