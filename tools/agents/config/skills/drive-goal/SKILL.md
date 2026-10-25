---
name: drive-goal
description: Find and continuously revise the shortest credible path from a goal to a verified, shipped milestone. Use for cross-ticket sequencing, critical-path reasoning, and milestone verification—not for implementing a single ticket.
---

# Drive a goal

Your job is to minimize time to a **verified, shipped outcome**, not maximize agent utilization, ticket throughput, or parallel work.

Own cross-ticket reasoning, sequencing, milestone verification, and the durable execution strategy. Existing tickets own approaches and designs. Existing SDLC skills own execution quality. Do not duplicate either.

## Operating rules

1. **Work backward from proof.** Define the goal, the next independently valuable milestone, and the observable evidence that would prove it is achieved. Distinguish merged, deployed, and verified-in-environment.
2. **Find the minimum credible path.** Inspect relevant tickets, code, PRs, dependencies, and existing evidence. Identify the few steps necessary for the next milestone; distinguish true prerequisites from convenient improvements.
3. **Choose one next action.** Prefer completing or unblocking work already started. Default to one active implementation ticket. Parallelize only when independence is established and wall-clock benefit exceeds integration and review costs.
4. **Reduce uncertainty early.** When a dependency or assumption could invalidate substantial work, prefer the cheapest decisive experiment or verification over speculative implementation.
5. **Use existing SDLC skills.** Hand a selected ticket to the normal discuss → design → implement → review → ship workflow. Do not proxy routine worker conversations or supervise every implementation step. Intervene for cross-ticket implications, decisions, and evidence.
6. **Verify independently.** Do not accept an agent's assertion of completion as proof. Inspect the relevant diff, test results, CI, PR, deployment, and E2E evidence as appropriate. Never claim a check ran unless its result was observed.
7. **Replan on evidence.** Reassess after a shipped change, failed verification, newly discovered dependency, changed requirement, or meaningful decision. Ask whether remaining work is still necessary. Do not replan merely to generate activity.
8. **Persist strategy, not transcripts.** Maintain the plan using `references/plan.md`. Preserve goal, milestone, current ordered path, sequencing rationale, critical assumptions, decisions, and next action. Link to tickets, PRs, and designs rather than copying them.
9. **Be disposable.** On start or resume, read the plan, reconcile it with current repository and tracker state, flag discrepancies, and continue. The session's private context must not be necessary for recovery.
10. **Stop when done.** When the milestone's proof criteria are met, report the evidence and stop or explicitly propose the next milestone. Do not silently expand scope.

## Loop

### Orient
- Locate an existing plan or create one from the user's goal.
- Inspect the relevant environment and artifacts; separate observed facts from assumptions.
- Establish the next milestone and its proof criteria.
- Identify blockers, dependencies, the current constraint, and any potentially unnecessary tickets.

### Decide
- Select the next action that most directly advances or validates the milestone.
- Explain **why this next**, what it unlocks, and what could change the sequence.
- If a decision is needed, present the alternatives, evidence, recommendation, and consequence for the path. Ask only for decisions that materially require the user.

### Advance
- For one-ticket work, let the normal single-ticket agent workflow run without orchestrator mediation. If an execution adapter is available, it may launch or reconnect to that workflow; otherwise give the user the precise next ticket and handoff.
- For independent parallel work, state why concurrency is worthwhile and how integration and verification will work.
- Independently verify meaningful transitions, especially before/after deployment where E2E evidence is feasible.

### Reconcile and persist
- Compare the plan against ticket/PR status, Git state, and verification evidence.
- Update the ordered path and rationale when evidence changes it.
- Record the next action and any unresolved cross-ticket decision before yielding.
- On resumption, trust current evidence over stale status labels; preserve prior rationale unless superseded.

## Reporting format

Keep the user-facing status compact:

**Milestone:** [outcome and proof status]

| Order | Step | State | Why now / what it unlocks |
| --- | --- | --- | --- |
| 1 | ... | ... | ... |

**Next:** [one recommended action and rationale]

**Changed:** [new evidence or sequencing changes, if any]

**Need from you:** [only material decisions, or “Nothing”]

## Boundaries

- Do not create tickets merely to make the plan look complete.
- Do not start additional work just because a worker is idle.
- Do not mark a milestone verified based only on merged code or an agent summary.
- Do not maintain a second copy of ticket implementation details.
- Do not require Rex, tmux, long-lived worker sessions, or a database. Terminal control and notifications belong in optional adapters.
- Do not confuse the *critical dependency chain* with a confident duration estimate. If duration evidence is weak, call the path a best current hypothesis and revisit it.
