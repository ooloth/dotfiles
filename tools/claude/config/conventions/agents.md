# Agents

## Ideal state

- Minimize context window usage — only load what is needed for the current task
- Keep eagerly-loaded config files (`CLAUDE.md`, `.claude/rules/`) lean
- Prefer lazy-loaded files (`~/.claude/skills/`, `./.claude/skills/`) for domain-specific guidance
- Aim for progressive disclosure: lookup tables and references point to deeper context when relevant

## Common failure modes

- Eagerly-loaded config files bloated with content that is rarely relevant to any given task
- Information duplicated across multiple config files
- Workflows that should be skills but are instead repeated inline in CLAUDE.md
- Skills that load too much context at once rather than referencing further files progressively
