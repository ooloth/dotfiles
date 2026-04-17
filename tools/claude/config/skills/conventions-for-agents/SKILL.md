---
name: conventions-for-agents
description: Preferred agent harness patterns when not otherwise specified by the project. TRIGGER when you are updating Claude Code configurations at the project-level or user-level.
model: opus
effort: high
---

## Context Management

- Minimize context window usage
- Minimize how much information is located in eagerly-loaded config files like `CLAUDE.md` and `.claude/rules/`
- Prefer lazy-loaded files like those in `~/.claude/skills` and `./.claude/skills`
- Aim for progressive disclosure via lookup tables and other references to what other context, scripts and other tools are available when relevant

Apply these conventions to the current task.
