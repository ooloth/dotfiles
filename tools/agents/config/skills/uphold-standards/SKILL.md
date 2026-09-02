---
name: uphold-standards
description: Load relevant universal engineering standards (decision-making and ADRs, architecture, testing, security, type design, documentation, etc.) and apply them to the current task. ALWAYS invoke before ANY technical decision, design, documentation or code change — including before writing or revising a decision record, choosing a tool, runtime, platform or data shape, or running a spike.
---

## Your task

1. Read `~/.agents/standards/README.md` to understand the framing and tier definitions
2. List `~/.agents/standards/` to see all available standards files
3. Load all files with a theme relevant to the current task. Include any language-specific file
   (e.g. `rust.md`, `python.md`) that matches the language(s) used in the current repository
4. If you notice a gap in the available guidance, feel free to mention what should be added (if no
   gap, say nothing)
5. Proactively apply the standards
