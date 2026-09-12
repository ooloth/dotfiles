---
name: uphold-standards
description: Load the universal engineering standards relevant to the change at hand (decision-making and ADRs, architecture, testing, security, type design, documentation, etc.) and apply them. Invoke at the start of each separate technical decision, design, documentation or code change, including every later one in the same session: an earlier invocation covers only the change it preceded and never the next one, so a session making four changes invokes this four times. Also invoke before writing or revising a decision record, choosing a tool, runtime, platform or data shape, or running a spike.
---

## Your task

1. Read `~/.agents/standards/README.md` to understand the framing and tier definitions
2. List `~/.agents/standards/` to see all available standards files
3. Load all files with a theme relevant to the current task. Include any language-specific file
   (e.g. `rust.md`, `python.md`) that matches the language(s) used in the current repository
4. If you notice a gap in the available guidance, feel free to mention what should be added (if no
   gap, say nothing)
5. Proactively apply the standards
