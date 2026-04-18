---
name: review-agent-harness
description: Preferred agent harness patterns when not otherwise specified by the project. TRIGGER when you notice you or another agent had trouble completing work quickly and correctly and better instructions or other harness tooling could help, or if the user asks you to help improve their Claude Code setup.
model: opus
effort: high
---

## Context

Use up to 25 subagents to explore the following data sources:

1. Study the `conventions-for-agents` reference skill guidance
2. Study the current project's documented agent harness intentions (if any)
3. Study the user's global Claude Code configuration in `~/.claude/` (custom skills, agents and settings are symlinked from ~/Repos/ooloth/dotfiles/tools/claude/config/)
4. Study the project-level Claude Code configuration in `./.claude/`
5. Study the user's recent Claude Code sessions in `~/.claude/projects/`
6. Study the Claude Code skills docs: https://code.claude.com/docs/en/skills
7. Study the Claude Code hooks docs: https://code.claude.com/docs/en/hooks-guide
8. Study the Claude Code subagents docs: https://code.claude.com/docs/en/sub-agents
9. Study the Claude Code agent teams docs: https://code.claude.com/docs/en/agent-teams
10. Study the Claude Code /loop docs: https://code.claude.com/docs/en/scheduled-tasks

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
   - `mkdir -p .agents`
   - Write the report to `.agents/review-conventions.html` — clean minimal styling, one slide per category plus a summary/title slide, keyboard arrow-key and click navigation between slides
   - `open .agents/review-conventions.html`
10. Recommend a next action and wait for the user's response
