---
name: scan-standards
description: Check whether a codebase upholds its standards — a specific theme or all themes in parallel. Use when asked to review conventions, check standards, or audit codebase health.
argument-hint: '[code-structure | code-readability | type-design | correctness | error-handling | security | privacy | data-integrity | testing | observability | performance | async-coordination | reliability | documentation | api-design | cli-design | dependencies | deployment | config | python | rust | typescript] [optional: path/glob or git-range e.g. src/api/ or main..HEAD]'
model: opus
effort: high
---

## Dispatch

**If the user specified a theme:**

1. Read `~/.agents/standards/README.md` to understand the framing and tier definitions
2. Load `~/.agents/standards/<theme>.md` (list `~/.agents/standards/` if unsure which file applies)
3. Study the current project's documented guidance for this concern (if any)
4. Use up to 50 subagents to explore the codebase (or the path/git-range if the user specified a smaller scope)
5. Identify violations of Must standards, deviations from Should standards, and unresolved Consider tradeoffs
6. Focus especially on patterns you would not want a future agent to spread

**If no theme was specified, continue below for a full parallel review.**

---

## Important: stay in your coordinator role

Do NOT invoke any Skill tools yourself. Instead, launch 7 Agent subagents in a **single message**
(so they run in parallel), with each review's full prompt inlined as shown below.

## Full review

1. Read `~/.agents/standards/README.md` and all reference files for each cluster below. Then launch
   all 7 Agent subagents in a **single message**, scoped to the entire codebase (or subsection if
   the user specified a smaller scope). Paste the relevant reference file contents into each agent's
   prompt. Each agent should return a structured list of findings with severity, location, and
   recommendation.

   Each subagent's prompt must include:
   - The full content of the relevant reference files
   - The tier definitions from README.md
   - This shared task: "Use up to 50 subagents to explore the codebase. Identify violations of Must
     standards, deviations from Should standards, and unresolved Consider tradeoffs. Focus
     especially on patterns you would not want a future agent to spread. Return findings as a
     structured list with severity (Must/Should/Consider), location, and recommendation."

   **Subagent 1 — Structure** (subagent_type: Explore, description: "review structure")
   Inline: `~/.agents/standards/code-structure.md`, `~/.agents/standards/code-readability.md`

   **Subagent 2 — Types & Correctness** (subagent_type: Explore, description: "review types and correctness")
   Inline: `~/.agents/standards/type-design.md`, `~/.agents/standards/correctness.md`,
   `~/.agents/standards/error-handling.md`

   **Subagent 3 — Security & Privacy** (subagent_type: Explore, description: "review security and privacy")
   Inline: `~/.agents/standards/security.md`, `~/.agents/standards/privacy.md`

   **Subagent 4 — Data** (subagent_type: Explore, description: "review data integrity")
   Inline: `~/.agents/standards/data-integrity.md`

   **Subagent 5 — Testing** (subagent_type: Explore, description: "review testing")
   Inline: `~/.agents/standards/testing.md`

   **Subagent 6 — Operations** (subagent_type: Explore, description: "review observability, performance, async coordination, and reliability")
   Inline: `~/.agents/standards/observability.md`, `~/.agents/standards/performance.md`,
   `~/.agents/standards/async-coordination.md`, `~/.agents/standards/reliability.md`

   **Subagent 7 — Documentation & Release** (subagent_type: Explore, description: "review documentation, API design, dependencies, deployment, and config")
   Inline: `~/.agents/standards/documentation.md`, `~/.agents/standards/api-design.md`,
   `~/.agents/standards/dependencies.md`, `~/.agents/standards/deployment.md`,
   `~/.agents/standards/config.md`

   Note: include language-specific files in the relevant agents when applicable:
   `~/.agents/standards/python.md` → Types & Correctness (if Python);
   `~/.agents/standards/rust.md` → Types & Correctness (if Rust);
   `~/.agents/standards/typescript.md` → Types & Correctness (if TypeScript);
   `~/.agents/standards/cli-design.md` → Structure (if the project has a CLI binary).

2. Wait for all subagents to return their results
3. Explore specific areas of the codebase yourself if needed to compare the relative importance of findings
4. Rank findings by priority (impact, cost of delay, ROI)
5. Present the prioritized findings with a summary table
6. Generate a self-contained HTML slide deck:
   - `mkdir -p .outputs/<yyyy-mm-dd>`
   - Write to `.outputs/<yyyy-mm-dd>/scan-standards.html` — clean minimal styling, one slide per category plus a title/summary slide, keyboard arrow-key and click navigation
   - `open .outputs/<yyyy-mm-dd>/scan-standards.html`
7. Recommend a next action and wait for the user's response
