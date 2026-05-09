---
name: review-conventions
description: Review codebase conventions — a specific domain or all domains in parallel. Use when asked to review or check conventions.
argument-hint: '[architecture | design | code-quality | type-design | correctness | assertions | error-handling | security | privacy | data-integrity | testing | operational-health | performance | concurrency | documentation | api-design | dependencies-deployment | python] [optional: path/glob or git-range e.g. src/api/ or main..HEAD]'
model: opus
effort: high
---

## Dispatch

**If the user specified a domain:**

1. Read `~/.claude/references/README.md` to understand the invariant framing and tier definitions
2. Load `~/.claude/references/<domain>.md` (list `~/.claude/references/` if unsure which file applies)
3. Study the current project's documented guidance for this concern (if any)
4. Use up to 50 subagents to explore the codebase (or the path/git-range if the user specified a smaller scope)
5. Identify violations of Must invariants, deviations from Should invariants, and unresolved Consider tradeoffs
6. Focus especially on patterns you would not want a future agent to spread

**If no domain was specified, continue below for a full parallel review.**

---

## Important: stay in your coordinator role

Do NOT invoke any Skill tools yourself. Instead, launch 7 Agent subagents in a **single message**
(so they run in parallel), with each review's full prompt inlined as shown below.

## Full review

1. Read `~/.claude/references/README.md` and all reference files for each cluster below. Then launch
   all 7 Agent subagents in a **single message**, scoped to the entire codebase (or subsection if
   the user specified a smaller scope). Paste the relevant reference file contents into each agent's
   prompt. Each agent should return a structured list of findings with severity, location, and
   recommendation.

   Each subagent's prompt must include:
   - The full content of the relevant reference files
   - The tier definitions from README.md
   - This shared task: "Use up to 50 subagents to explore the codebase. Identify violations of Must
     invariants, deviations from Should invariants, and unresolved Consider tradeoffs. Focus
     especially on patterns you would not want a future agent to spread. Return findings as a
     structured list with severity (Must/Should/Consider), location, and recommendation."

   **Subagent 1 — Structure** (subagent_type: Explore, description: "review structure")
   Inline: `~/.claude/references/architecture.md`, `~/.claude/references/design.md`,
   `~/.claude/references/code-quality.md`

   **Subagent 2 — Types & Correctness** (subagent_type: Explore, description: "review types and correctness")
   Inline: `~/.claude/references/type-design.md`, `~/.claude/references/correctness.md`,
   `~/.claude/references/assertions.md`, `~/.claude/references/error-handling.md`

   **Subagent 3 — Security & Privacy** (subagent_type: Explore, description: "review security and privacy")
   Inline: `~/.claude/references/security.md`, `~/.claude/references/privacy.md`

   **Subagent 4 — Data** (subagent_type: Explore, description: "review data integrity")
   Inline: `~/.claude/references/data-integrity.md`

   **Subagent 5 — Testing** (subagent_type: Explore, description: "review testing")
   Inline: `~/.claude/references/testing.md`

   **Subagent 6 — Operations** (subagent_type: Explore, description: "review operational health")
   Inline: `~/.claude/references/operational-health.md`, `~/.claude/references/performance.md`,
   `~/.claude/references/concurrency.md`

   **Subagent 7 — Documentation & Deployment** (subagent_type: Explore, description: "review documentation and deployment")
   Inline: `~/.claude/references/documentation.md`, `~/.claude/references/api-design.md`,
   `~/.claude/references/dependencies-deployment.md`

   Note: include `~/.claude/references/python.md` in the Types & Correctness agent if the codebase
   contains Python.

2. Wait for all subagents to return their results
3. Explore specific areas of the codebase yourself if needed to compare the relative importance of findings
4. Rank findings by priority (impact, cost of delay, ROI)
5. Present the prioritized findings with a summary table
6. Generate a self-contained HTML slide deck:
   - `mkdir -p .agents/<yyyy-mm-dd>`
   - Write to `.agents/<yyyy-mm-dd>/review-conventions.html` — clean minimal styling, one slide per category plus a title/summary slide, keyboard arrow-key and click navigation
   - `open .agents/<yyyy-mm-dd>/review-conventions.html`
7. Recommend a next action and wait for the user's response
