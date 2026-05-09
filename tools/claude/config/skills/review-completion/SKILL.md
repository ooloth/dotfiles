---
name: review-completion
description: Confirm a task was fully executed and the change works — static completeness audit followed by empirical runtime evidence. TRIGGER when asked to confirm a task is complete, prove it works, or verify a change is ready to ship.
argument-hint: '[task number, issue, or description — defaults to current branch]'
effort: high
model: opus
---

## Context

- The task or scope to review is: $ARGUMENTS
- If not specified, assume the changes on the current branch relative to the original plan
- If there is no recent task (e.g. this is a standalone runtime check on existing code), note it
  — Phases 2–3 will be brief

## Phase 1: Understand Intent and Load Invariants

1. If the scope is unclear, ask before continuing
2. Read `~/.claude/references/README.md` and the reference files relevant to the change scope
3. Use as many subagents as needed to explore the problem definition, all relevant code paths,
   documentation, and the changes made
4. Identify the observable outputs available to validate behaviour from the outside while treating
   the system's implementation as a black box
5. Proactively answer every question that occurs to you by exploring the codebase
6. Wait for all subagents to return before continuing

---

## Phase 2: Static Completeness Audit

Compare the current state of the code against the intended goal:

1. Was the complete intention of the original task achieved? What evidence proves that?
2. Have all edge cases been handled? What evidence proves that?
3. Is the chosen approach as declarative and straightforward as it could be?
4. Have domain concepts been modelled using well-designed custom types?
5. Do all branches have well-designed automated tests? Do the tests prove this change introduces
   no regressions across all relevant logical branches and side effects?
6. Can the expected behaviour of every branch be confirmed from the outside — by running the real
   system and observing its output — without relying on automated tests?
7. If your team says "prove this does not break anything", what can you show them?

---

## Phase 3: Instrumentation Check

For user-facing or behaviour-changing changes, verify that observability shipped with the feature:

- [ ] **North-star metric** — the one number expected to move; is it defined?
- [ ] **Baseline** — current value captured before the change?
- [ ] **Expected direction & size** — e.g. +5% conversion, –20% latency
- [ ] **Time horizon** — when will we check? (7 days? 30?)
- [ ] **Guardrail metrics** — what must _not_ get worse (error rate, adjacent funnels)?
- [ ] **How we'll read it** — A/B, before/after, cohort, or qualitative signal defined?

If instrumentation was not shipped in the same change, flag it explicitly. "We'll add analytics
later" is a gap — call it out and recommend adding it before or immediately after this ships.

Skip this phase if the change is purely internal (refactor, dev tooling, CI, etc.).

---

## Phase 4: Present Static Findings + Runtime Validation Plan

Present two things and then **stop and wait for approval**:

**A) Static findings summary** — what Phases 2–3 found: gaps, missing edge cases, instrumentation
holes, or a clean bill of health. Be specific; reference file paths and line numbers.

**B) Runtime validation plan** — for each claim about runtime behaviour, state concretely:
- What command you will run
- What process output, DB query result, or log lines you will capture
- How that output proves the claim

**Hard constraints on evidence sources:**
- Automated tests do not count — not as proof, not even as a component of proof
- No mocking, no test fixtures, no `pytest` — only the real process, real DB, real I/O, real logs
- If you find yourself reaching for a test file to prove something, stop and ask: "how would I
  observe this behaviour if I had no test suite at all?" That is the question to answer

If adding observability signals first would materially improve your ability to collect evidence,
propose those changes here — they are likely to be approved.

Wait for explicit approval before continuing to Phase 5.

---

## Phase 5: Run All Code Paths and Collect Evidence

1. Execute the approved validation plan using as many subagents as needed
2. Wait for all subagents to return
3. Confirm every code path has been executed
4. Confirm every intended behaviour has been validated with hard evidence
5. Confirm every invariant has been validated with hard evidence
6. All evidence must come from the running system — screen recordings, screenshots, captured
   output, log lines. Automated test results do not count.

---

## Phase 6: Present Findings

1. Present prioritised findings with a summary table — one row per behaviour or invariant checked,
   with status (pass / fail / gap) and evidence reference
2. Generate a self-contained HTML slide deck:
   - `mkdir -p .outputs/<yyyy-mm-dd>/<branch>`
   - Write to `.outputs/<yyyy-mm-dd>/<branch>/review-completion.html` — clean minimal styling,
     one slide per category plus a summary/title slide, keyboard arrow-key and click navigation
   - `open .outputs/<yyyy-mm-dd>/<branch>/review-completion.html`
3. Recommend a next action and wait for the user's response
