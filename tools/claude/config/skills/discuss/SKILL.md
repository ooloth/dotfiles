---
name: discuss
description: Explore a task and validate the overall strategy before implementation. TRIGGER for ambiguous tasks, design discussions, multi-step work, risky changes, or when the user asks a question before implementation.
argument-hint: '[task number or description]'
effort: high
model: opus
---

## Context

- The task (or issue, problem, ticket, etc) the user wants to discuss is what they mentioned here: $ARGUMENTS

## Your task

This is a discussion/strategy skill. Do not make side-effecting changes while using it: no edits,
writes, mutating shell commands, commits, posted comments, or ticket creation. Read-only exploration
is allowed when needed. Do not plan fine implementation details (type design, slices, tests) — that
belongs to `/design`, which runs after the user approves the approach.

### Phase 1: Load Context Progressively

1. Read `~/.claude/references/README.md` and list `~/.claude/references/` only when invariants or
   architectural constraints may affect the approach decision.
2. Load only the reference files obviously relevant to the task.
3. Load additional reference files only when the investigation shows they matter.
4. If the task scope is still unclear, prefer asking a clarifying question over loading every file.

### Phase 2: Understand Intent

1. If the user did not specify what they want to discuss, ask them for that information.
2. If the user asked a question, answer the question before proposing anything.
3. Use read-only exploration and subagents only as needed to understand the current code, docs,
   constraints, and likely impact.
4. If the idea seems stale or poorly matched to the current codebase, investigate enough to help the
   user decide whether to redefine, defer, or skip it.
5. Ask only questions that block a correct approach decision. For two-way-door decisions, recommend
   a default and move on instead of making the user decide everything.

### Phase 3: Recommend an Approach

1. Recommend the simplest approach that achieves the intended outcome. Push back on unnecessary
   scope, abstractions, configurability, or compatibility work.
2. For non-trivial decisions, name tradeoffs explicitly — frame options as "optimize for X vs Y",
   not "right vs wrong":

   | Dimension       | Question                                  |
   | --------------- | ----------------------------------------- |
   | **Value**       | What outcome does this unlock?            |
   | **Cost**        | Time, complexity, ongoing maintenance     |
   | **Risk**        | What breaks if we're wrong? Who pays?     |
   | **Alternative** | What did we consider and reject, and why? |

3. Flag reversibility for each significant decision:
   - **Two-way door** (easily reversible) — recommend a default, decide fast, and move on.
   - **One-way door** (costly to undo: public APIs, data schemas, pricing, core UX patterns users
     learn) — requires explicit sign-off; include an ADR-lite entry in the plan:

   ```
   ## Decision: [short title]
   Context: [problem, constraints]
   Options considered: [A, B, C]
   Choice: [X], because [reason]
   Reversibility: one-way door
   Revisit trigger: [metric / date / condition that reopens this]
   ```

### Phase 4: Present and Stop

End with a strategy artifact:

1. **Understanding** — what the user wants and any assumptions
2. **Findings** — relevant code/docs/current-state facts discovered
3. **Recommendation** — preferred approach and why
4. **Open decisions** — only decisions that block correct implementation
5. **Approval request** — ask the user to approve this approach, and offer to run `/design` next
   to produce the type story, test plan, and implementation slices

If the user answers clarifying questions, incorporate the answers, present the updated strategy,
and stop again. Do not treat answers to questions as approach approval.

When the user explicitly approves the approach, recommend running `/design` to translate it into a
concrete implementation plan before any code is written.
