# Plans

A plan is a single, continuously-built document that walks from problem to
implementation-ready design, foundation before derived, with one approval
gate in the middle.

## Template

```
## Problem statement
## Current state
## Ideal state
## Verification
## Constraints
## Priorities
## Questions
## Approach alternatives considered
## Approach decision
--- approval gate ---
## Implementation alternatives considered
## Implementation decision
## Types / data shape
## Test plan
## Structure / boundaries
## QA plan
## Assumptions
## Out of scope
## Open questions
```

## Must

**Current state states observable fact; ideal state states independently
verifiable fact.** Neither describes implementation steps.

**Every ideal-state claim has a matching Verification entry.** A claim with
no way to check it isn't a claim, it's a hope.

**QA plan steps trace back to a Verification entry.** Nothing appears in
the concrete walkthrough that the abstract commitment didn't already cover.

**Approach decision names a strategy, not a mechanism.** Data structures,
algorithms, file layout, and library choices belong to Implementation
decision. A caching daemon vs. an async read path is Approach; SQLite vs.
in-memory is Implementation.

**Types and Test plan do not appear before Implementation decision is
recorded.** The concrete design is derived from the decision, not the
reverse.

**Questions asked while establishing the foundation are recorded in
Questions with their answers, tagged by whether resolved by the user or by
investigation.** A claim in Current state, Constraints, or Priorities that
isn't traceable to either is indistinguishable from a guess.

**Every claim is either verified, with how, or flagged as an assumption.**
An untagged claim is a defect regardless of whether it turns out to be true.

**An assumption that contradicts observable code or config is surfaced, not
silently recorded as fact.** If the user states how something works and the
codebase disagrees, the contradiction becomes an open question — not a
quietly resolved assumption in either direction.

## Should

**At least one rejected alternative appears for any Approach or
Implementation decision non-trivial enough that Priorities matters to it.**
Zero alternatives on a decision substantial enough to need this doc reads
as an unworked tree, not an obvious choice — indistinguishable to a cold
reader without the alternative on record.

**An assumption that would change Approach decision or Implementation
decision if it turned out false has a corresponding entry in Questions.**
Assumptions holds only things that don't move the needle if wrong.

**Priorities are stated once, in the foundation, and referenced — not
re-derived — by Implementation decision.** Restating them risks a quiet
drift between what Approach decision optimized for and what Implementation
decision ends up optimizing for.

**Space given to a decision is proportional to its cost of reversal and its
surprise value, not to a fixed length.** A cheap, obvious pick earns a
sentence. An irreversible, non-obvious one earns whatever it needs.

## Consider

**Implementation alternatives considered may be a single line noting none
existed**, when the mechanism was genuinely the only reasonable one once
Approach decision was made — the heading stays, the content doesn't have
to pretend a choice was harder than it was.

## In scope

- Any implementation task that is ambiguous, multi-step, or hard to reverse
- Any task with a real design decision — strategic or mechanism-level — to make before implementation starts

## Out of scope

- Trivial, unambiguous one-line fixes
- Purely exploratory research with no implementation expected to follow
