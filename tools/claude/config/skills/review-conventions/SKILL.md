---
name: review-conventions
description: Perform a comprehensive review of all codebase conventions using subagents and report your findings. Use when asked to review the codebase or identify opportunities to improve it.
effort: high
---

## Important: stay in your coordinator role

Do NOT invoke any Skill tools yourself. Doing so would load that skill's instructions into your own context, causing you to start executing it directly instead of delegating. Instead, launch 6 Agent subagents in a **single message** (so they run in parallel), with each review's full prompt inlined as shown below.

## Your task

1. Read the SKILL.md files for each review and its corresponding conventions reference (12 files total — see paths below). Then launch all 6 Agent subagents in a **single message** (so they run in parallel), scoped to the entire codebase (or subsection if the user specified a smaller scope). Paste the contents of both SKILL.md files into each agent's prompt so the agent has the full context. Each agent should return a structured list of findings with severity, location, and recommendation.

   **Subagent 1 — Architecture** (subagent_type: Explore, description: "review architecture")
   Read and inline: `~/.claude/skills/review-architecture/SKILL.md` + `~/.claude/skills/conventions-for-architecture/SKILL.md`

   **Subagent 2 — Documentation** (subagent_type: Explore, description: "review documentation")
   Read and inline: `~/.claude/skills/review-documentation/SKILL.md` + `~/.claude/skills/conventions-for-documentation/SKILL.md`

   **Subagent 3 — Observability** (subagent_type: Explore, description: "review observability")
   Read and inline: `~/.claude/skills/review-observability/SKILL.md` + `~/.claude/skills/conventions-for-observability/SKILL.md`

   **Subagent 4 — Tests** (subagent_type: Explore, description: "review tests")
   Read and inline: `~/.claude/skills/review-tests/SKILL.md` + `~/.claude/skills/conventions-for-tests/SKILL.md`

   **Subagent 5 — Types** (subagent_type: Explore, description: "review types")
   Read and inline: `~/.claude/skills/review-types/SKILL.md` + `~/.claude/skills/conventions-for-types/SKILL.md`

   **Subagent 6 — Code style** (subagent_type: Explore, description: "review code style")
   Read and inline: `~/.claude/skills/review-code-style/SKILL.md` + `~/.claude/skills/conventions-for-code-style/SKILL.md`

2. Wait for all 6 subagents to return their results
3. Ensure you understand the results and are equipped to compare their relative importance (explore specific areas of the codebase yourself if that helps you)
4. Rank the findings by priority for the user to address (based on impact, cost of delay, ROI, etc)
5. Present the prioritized findings to the user, ensuring a summary table is included near the end of your response for clarity
6. Recommend a next action and wait for the user's response
