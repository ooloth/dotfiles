---
name: review-conventions
description: Review codebase conventions — a specific domain or all domains in parallel. Use when asked to review or check conventions.
argument-hint: '[architecture | code-style | documentation | observability | tests | types] [optional: path/glob or git-range e.g. src/api/ or main..HEAD]'
model: opus
effort: high
---

## Dispatch

**If the user specified a domain:**

1. Identify which conventions to load:
   - If a domain was named, load `~/.claude/conventions/<domain>.md`
   - If no domain but a scope was given, list `~/.claude/conventions/` and load whichever files are relevant
   - State which file(s) you loaded before proceeding
2. Study the current project's documented guidance for this concern (if any)
3. Use up to 50 subagents to explore the codebase (or the path/git-range if the user specified a smaller scope)
4. Identify deviations from the ideal state and instances of the failure modes
5. Focus especially on patterns you would not want a future agent to spread

**If no domain was specified, continue below for a full parallel review.**

---

## Important: stay in your coordinator role

Do NOT invoke any Skill tools yourself. Instead, launch 6 Agent subagents in a **single message** (so they run in parallel), with each review's full prompt inlined as shown below.

## Full review

1. Read all 6 convention files from `~/.claude/conventions/`: `architecture.md`, `code-style.md`, `documentation.md`, `observability.md`, `tests.md`, `types.md`. Then launch all 6 Agent subagents in a **single message**, scoped to the entire codebase (or subsection if the user specified a smaller scope). Paste the conventions file content into each agent's prompt. Each agent should return a structured list of findings with severity, location, and recommendation.

   Each subagent's prompt must include:
   - The full content of the relevant conventions file
   - This shared task: "Use up to 50 subagents to explore the codebase. Identify deviations from the ideal state and instances of the failure modes described above. Focus especially on patterns you would not want a future agent to spread. Return findings as a structured list with severity, location, and recommendation."

   **Subagent 1 — Architecture** (subagent_type: Explore, description: "review architecture")
   Inline: `~/.claude/conventions/architecture.md`

   **Subagent 2 — Code style** (subagent_type: Explore, description: "review code style")
   Inline: `~/.claude/conventions/code-style.md`

   **Subagent 3 — Documentation** (subagent_type: Explore, description: "review documentation")
   Inline: `~/.claude/conventions/documentation.md`

   **Subagent 4 — Observability** (subagent_type: Explore, description: "review observability")
   Inline: `~/.claude/conventions/observability.md`

   **Subagent 5 — Tests** (subagent_type: Explore, description: "review tests")
   Inline: `~/.claude/conventions/tests.md`

   **Subagent 6 — Types** (subagent_type: Explore, description: "review types")
   Inline: `~/.claude/conventions/types.md`

2. Wait for all 6 subagents to return their results
3. Explore specific areas of the codebase yourself if needed to compare the relative importance of findings
4. Rank findings by priority (impact, cost of delay, ROI)
5. Present the prioritized findings with a summary table
6. Generate a self-contained HTML slide deck:
   - `mkdir -p .agents/<yyyy-mm-dd>`
   - Write to `.agents/<yyyy-mm-dd>/review-conventions.html` — clean minimal styling, one slide per category plus a title/summary slide, keyboard arrow-key and click navigation
   - `open .agents/<yyyy-mm-dd>/review-conventions.html`
7. Recommend a next action and wait for the user's response
