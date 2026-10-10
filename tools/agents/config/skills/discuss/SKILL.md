---
name: discuss
description: Explore a task and validate the overall strategy before implementation. TRIGGER for ambiguous tasks, design discussions, multi-step work, risky changes, or when the user asks a question before implementation.
argument-hint: '[task number or description]'
effort: high
model: opus
---

## Context

- The task (or issue, problem, ticket, etc) the user wants to discuss is what they mentioned here:
  $ARGUMENTS

## Your task

This is a discussion/strategy skill. Do not make side-effecting changes while using it: no edits,
writes, mutating shell commands, commits, posted comments, or ticket creation. Read-only exploration
is allowed when needed. Do not plan fine implementation details (type design, slices, tests) — that
belongs to `/design`, which runs after the user approves the approach.

### Phase 1: Load Context Progressively

1. Read `~/.agents/standards/README.md` and `~/.agents/standards/decision-making.md`. Both always
   apply: recommending an approach is a decision.
2. List `~/.agents/standards/` and load any other file whose theme matches the task.
3. Load additional standards files only when the investigation shows they matter.
4. If the task scope is still unclear, prefer asking a clarifying question over loading every file.
5. Read the project's recorded decisions. List the titles in `DECISIONS.md`, `docs/decisions/`,
   `docs/adr/`, `doc/adr/`, `adr/` and `docs/architecture/decisions/`, and search the repo for
   "ADR". A project may record decisions somewhere else, so also check its `CLAUDE.md`,
   `AGENTS.md`, `README.md` and `docs/README.md` for where it says decisions live. Open a record
   only when its title touches the task. If the task came from a ticket with a **Decisions**
   section, repeat this search anyway: records may have been added or superseded since the ticket
   was written, and its author knew less than you do now.

### Phase 2: Understand Intent

1. If the user did not specify what they want to discuss, ask them for that information.
2. If the user asked a question, answer the question before proposing anything.
3. Use read-only exploration and subagents only as needed to understand the current code, docs,
   constraints, and likely impact.
4. Find out what the simplest fix would break by running it, not only by reading it. In a copy of
   the repo under `mktemp -d`, apply the most obvious fix the ticket suggests, then run every path
   that fix can reach, with external tools replaced by stubs that succeed and then fail. Compare
   each result with today's. A path whose result changes in a way the ticket did not ask for is a
   risk the approach must cover. Never edit the repo itself, and delete the copy when done.
5. If the idea seems stale or poorly matched to the current codebase, investigate enough to help the
   user decide whether to redefine, defer, or skip it.
6. Facts are your job, not the user's — dispatch subagents to find them. Ask the user only what
   blocks a correct approach decision, and batch those into one numbered round with a recommended
   answer for each rather than drip-feeding one question per turn. Don't ask about anything still
   gated on a question you haven't gotten an answer to yet. For a two-way-door decision, derive a
   recommendation from the properties rather than handing the choice to the user. Being easy to
   reverse does not excuse skipping the derivation.

### Phase 3: Recommend an Approach

A recorded decision that covers the task is a constraint on every option below. An option that
contradicts one is not taken quietly: superseding the record is an open decision in its own right,
presented under **Open decisions** with the record linked. Where applying a record to this task
takes interpretation, whether it applies is also an open decision.

1. Derive the properties a good answer must have, from what the system will actually do, before
   considering any option. Not from what the ticket or existing docs say it needs; that is the
   previous author's list and it reads as complete because it was written as a summary. State each
   as an observable property, and say which bind and which do not.

   Observable means something observes it. For each property that binds, name what does: a type, a
   test, an assertion, a check against recorded state, or a measurement that already exists. Where
   nothing does, taking that measurement is part of the work rather than an assumption carried past
   this point. A property nobody can observe is an intention, and every option below is scored
   against this list.

   Scope each property to the behaviour this work changes. Where a risk this work exposes could be
   stated broadly enough to bind code the work does not otherwise touch, state it at the narrowest
   scope that still covers that risk, and name what it deliberately leaves uncovered among the
   properties that do not bind. A broad property becomes an instruction to change and test code the
   ticket never asked about.

   An observer counts only if it covers every place the property could be broken, including code
   added later. A property that only this work's code can break is covered by tests of that code.
   A property that code elsewhere can break, such as a rule every handler or every config file
   follows, is cross-cutting: its observer is a check over every instance, not a test of the
   instances this work creates. Mark each cross-cutting property as such. The project also records
   it, in `docs/invariants/` when it has no sanctioned exception or in `docs/standards/` when it
   has one, so whoever writes the code that could break it reads the rule before the check fails.
   Where the project has neither folder, creating one is an open decision.

2. Recommend the simplest approach that delivers those properties. Simplicity is how a property is
   reached cheaply, never a reason to drop one. Push back on scope, abstraction, configurability or
   compatibility work that no stated property requires.

3. Implementation effort is a constraint, never a merit. It rules an option out only against a
   budget the user stated. "X is simpler to build" is not a reason to prefer X unless it also names
   a property X delivers better. Cost is what an option spends to deliver the properties, not a
   score it competes on, unless the user has stated a view on it, in which case it enters the table
   as a row citing that statement.

4. Score every option against every property in one table, options as rows and properties as
   columns. Before accepting any tradeoff, state the theoretical maximums for safety, performance
   and experience for the thing being decided, as `decision-making.md` defines them, and look for a
   design that comes close to all three. First list the ways a bad design could go wrong or cause
   harm, be slow, or be hard to use or change, in all three categories and not only the one the task
   is about. Options
   framed as points on one curve,
   such as "fast or correct" or "simple or safe", are the sign this step was skipped. A tradeoff
   that remains names the physical fact that forces it.

   If more than one option survives, the list is not finished. Zoom into each property every
   survivor passes, and extend the list to moments and softer properties not yet covered, each
   citing its source. Score again. An unknown cell is resolved before the option it belongs to is
   kept or dropped. Recommend only what the table yields, and present the passes that got there.

5. Flag reversibility for each significant decision:
   - **Two-way door** (easily reversible) — it may be taken earlier than a one-way door, but it is
     derived and scored just as carefully. Reversibility lowers the cost of being wrong, not the
     care owed to being right.
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

   A revisit trigger naming a metric requires that metric to exist. Where nothing records it,
   recording it is part of the decision rather than a later step: a trigger keyed to a measurement
   nobody takes never fires, and the record then reads as revisitable while being permanent.
   `decision-making.md` asks for the observable condition that would reopen a decision, and an
   unobservable one does not satisfy it.

6. Where the approach spans processes, asynchronous work, or separate runs, settle what ties events
   together across that boundary and where anything durable is kept. `decision-making.md` names a
   missing identifier that turns a later feature into a migration as a canonical example of an
   option closed without anyone noticing, and a correlation identifier is exactly that: adding one
   later means changing every interface it crosses. Whether a store exists that a later check can
   read, and which one, is the same kind of decision, since a slice can conform to such a store but
   cannot invent one. Name both, or name their absence, so `/design` is not left to improvise a
   mechanism from inside a single slice.

### Phase 4: Present and Stop

Before presenting, review what you are about to claim:

1. Every claim is either verified — with how — or explicitly tagged as an assumption. An untagged
   claim is a defect regardless of whether it turns out to be true.
2. For each assumption, ask "would this being wrong change the recommendation?" If yes and
   investigation can settle it, settle it before presenting. If only the user or someone outside the
   repo can settle it, it goes in open decisions with a recommended answer, not in assumptions.
3. An assumption that contradicts observable code or config is surfaced, not silently recorded as
   fact. If the user states how something works and the codebase disagrees, the contradiction
   becomes an open question — not a quietly resolved assumption in either direction.

End with the approach, written the same way in the terminal and in the ticket comment, so a reader
sees what was chosen first and how it was chosen right after:

1. `# Approach`, then one paragraph saying what the chosen approach does.
2. `## What a good fix must achieve 🎯`: a table with an empty first header, a `Property` column and
   a `Category` column, one row per binding property, numbered `P1`, `P2` and so on, each in one
   line. `Category` is `🛡️ Safety`, `⚡ Performance` or `🙂 Experience`. Safety covers everything
   about the system going wrong or causing harm that is not about speed or ease of use:
   correctness, reliability, security, data integrity and the like. Leave out properties that do
   not bind. This table is also the done-when. A cross-cutting property's row says it is checked
   over every instance.
3. `## Assumptions 🤔`: only those that, if wrong, would change which option wins. Write what you
   observed about each into its wording rather than labelling it checked or unchecked.
4. `## Constraints 🧱`: facts about the code or environment that limit which options can work. Only
   when there are some.
5. `## Options ⚖️`: a table with `Option`, then one column per property (`P1`, `P2`, …) and nothing
   else. The chosen option is the first row, in bold, starting with 🏆 and ending in "(chosen)".
   Every cell is ✅ or ❌. Leave no cell unknown: settle it by running something.
6. `## Decided by 🧭`: one short paragraph reasoning through what separated the options still
   standing, including when they all score ✅.
7. `## How it fits 🗺️`: a Mermaid diagram of the chosen approach, only when it shows the approach
   more clearly than the paragraph does. Where the approach changes how components, processes or
   runs interact, it shows that, drawn to the diagram standards in
   `~/.agents/standards/documentation.md`, and marks what ties events together across a boundary
   and where anything durable is kept.
8. `## Deferred ⏳`: only when discussion found something worth doing that this work does not do,
   such as a fix to a deeper cause that lies outside the ticket, or a bug found on the way.

In the terminal, follow it with `## Open decisions ❓`, only those that block correct implementation,
numbered, each with a recommended answer, and then the approval request, offering to run `/design`
next.

Write for someone who opens the ticket with no context and a few seconds to spare: a teammate, or
the user in three months. They came for the decision: what was chosen, what it had to achieve, and
why it beat the alternatives. Everything you did to reach it, such as the runs, the commands, the
line numbers and the dead ends, was for you, not them, and stays in this session. Say each thing
once, in the plainest words that carry it, and stop when the decision is clear. A sentence that
would not change what the reader understands, or what they would want to check, does not belong. The
opening paragraph says what the approach does, not the evidence for it. A property says what must be
true, not how it is checked or which files are involved. Nothing appears outside the sections above.

When the work is on a ticket, the comment is the approach above without the open decisions and the
approval request. Draft it for the user, and post it once they approve that wording.

If the user answers clarifying questions, incorporate the answers, present the updated strategy,
and stop again. Do not treat answers to questions as approach approval.

When the user explicitly approves the approach, recommend running `/design` to translate it into a
concrete implementation plan before any code is written.
