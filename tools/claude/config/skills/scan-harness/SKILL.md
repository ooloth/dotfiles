---
name: scan-harness
description: Audit the user's Claude Code agent harness for improvements — global config, project config, recent session patterns, and opportunities for better guardrails and feedback loops. Use when the user asks to improve their Claude Code setup.
model: opus
effort: high
---

## Context

Use up to 25 subagents to explore the following data sources:

1. Study the current project's documented agent harness intentions (if any)
2. Study the user's global Claude Code configuration in `~/.claude/` (custom skills, agents and settings are symlinked from ~/Repos/ooloth/dotfiles/tools/claude/config/)
3. Study the project-level Claude Code configuration in `./.claude/`
4. Study the user's recent Claude Code sessions in `~/.claude/projects/`
5. Study the Claude Code skills docs: https://code.claude.com/docs/en/skills
6. Study the Claude Code hooks docs: https://code.claude.com/docs/en/hooks-guide
7. Study the Claude Code subagents docs: https://code.claude.com/docs/en/sub-agents
8. Study the Claude Code agent teams docs: https://code.claude.com/docs/en/agent-teams
9. Study the Claude Code /loop docs: https://code.claude.com/docs/en/scheduled-tasks

## Your task

1. Identify opportunities to improve the user's global Claude Code configuration
2. Identify opportunities to improve the current repo's project-level Claude Code configuration
3. Identify opportunities in the patterns you see across recent Claude Code sessions
4. Look for opportunities that would provide the context needed to help agents understand the intent of the project and make correct judgement calls
5. Look for opportunities to introduce clear guardrails helping agents validate their work
6. Focus especially on opportunities to introduce deterministic mechanisms that introduce reliable back pressure and a feedback loop that makes it obvious to agents what choices are correct and what invariants they must uphold at all times
7. Rank the findings by priority for the user to address (based on impact, cost of delay, ROI, etc)
8. Present the prioritized findings to the user, ensuring a summary table is included near the end of your response for clarity
9. Generate a self-contained HTML slide deck of the prioritized findings:
   - `mkdir -p .outputs/<yyyy-mm-dd>`
   - Write the report to `.outputs/<yyyy-mm-dd>/scan-harness.html` — clean minimal styling, one slide per category plus a summary/title slide, keyboard arrow-key and click navigation between slides
   - `open .outputs/<yyyy-mm-dd>/scan-harness.html`
10. Recommend a next action and wait for the user's response
