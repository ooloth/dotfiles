---
name: discuss
description: Plan an implementation before acting. TRIGGER for ambiguous tasks, design discussions, multi-step work, risky changes, or when the user asks a question before implementation.
argument-hint: '[task number or description]'
effort: high
model: opus
---

## Context

- The task (or issue, problem, ticket, etc) the user wants to discuss is what they mentioned here: $ARGUMENTS

## Your task

This is a discussion/planning skill. Do not make side-effecting changes while using it: no edits,
writes, mutating shell commands, commits, posted comments, or ticket creation. Read-only exploration
is allowed when needed.

### Phase 0: Decide Depth

Classify the task before exploring:

| Depth                    | Use when                                                                                                  | Behavior                                                     |
| ------------------------ | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| **Trivial / clear**      | The desired change and implementation path are obvious                                                    | Answer directly; ask at most one blocking question           |
| **Ambiguous**            | The goal, scope, or acceptance criteria are unclear                                                       | Clarify intent, then propose a plan                          |
| **Multi-step**           | The work spans files, domains, tests, migrations, or multiple commits                                     | Explore relevant paths and propose slices                    |
| **Risky / one-way-door** | Public APIs, data schemas, pricing, security, irreversible data changes, or core UX patterns are involved | Explore deeply and require explicit sign-off on the decision |

Scale investigation to the classification. Do not turn small tasks into heavyweight planning.

### Phase 1: Load Context Progressively

1. Read `~/.claude/references/README.md` and list `~/.claude/references/` when invariants may
   affect the plan.
2. Load only the reference files obviously relevant to the task.
3. Load additional reference files only when the investigation shows they matter.
4. If the task scope is still unclear, prefer asking a clarifying question over loading every file.

### Phase 2: Understand Intent

1. If the user did not specify what they want to discuss, ask them for that information.
2. If the user asked a question, answer the question before proposing implementation.
3. Use read-only exploration and subagents only as needed to understand the current code, docs,
   constraints, and likely impact.
4. If the idea seems stale or poorly matched to the current codebase, investigate enough to help the
   user decide whether to redefine, defer, or skip it.
5. Ask only questions that block a correct plan. For two-way-door decisions, recommend a default and
   move on instead of making the user decide everything.

### Phase 3: Design the Solution

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

4. Recommend whether the implementation belongs in one small change, multiple stacked changes, or
   multiple parallel changes.
5. Define how each implementation slice will be validated, including live execution evidence (what
   you ran, what you observed) or why live execution is impossible.

### Phase 4: Present the Plan and Stop

End with a concrete plan artifact:

1. **Understanding** — what the user wants and any assumptions
2. **Findings** — relevant code/docs/current-state facts discovered
3. **Recommendation** — preferred approach and why
4. **Open decisions** — only decisions that block correct implementation
5. **Implementation plan** — small, commit-worthy slices and PR strategy
6. **Validation plan** — checks, tests, and live execution evidence for each slice
7. **Approval request** — ask the user to explicitly approve implementation

If the user answers clarifying questions, incorporate the answers, present the full plan, and stop
again for explicit approval. Do not treat answers to questions as implementation approval.

When the user explicitly approves implementation, the next implementation agent must create or
update a Trekker task before reading or writing implementation files, then proceed with the first
small slice.
