---
name: design
description: Design the type progression, assertion plan, telemetry plan and test plan for approved work. Invoke after agreeing on the high-level approach and before writing any implementation.
argument-hint: '[task description or Trekker task number]'
effort: high
model: opus
---

## Context

- Agreed task: $ARGUMENTS

## Your task

This is a design skill. Do not make side-effecting changes: no edits, writes, mutating shell
commands, commits, or ticket creation. Read-only exploration is allowed.

### Phase 1: Understand the Scope

1. Read the agreed objective from $ARGUMENTS — if it's a Trekker task number, read that task; if
   it's a description, use it directly. Ask the user to clarify if the scope is still ambiguous.
2. Load `~/.agents/standards/type-design.md`, `~/.agents/standards/correctness.md`,
   `~/.agents/standards/testing.md` and `~/.agents/standards/decision-making.md`. The last applies
   because Phase 2 chooses between options. Also load any language-specific reference file that
   applies to this codebase (`~/.agents/standards/rust.md`, `~/.agents/standards/python.md`, etc.).
3. Explore the codebase to understand:
   - Existing domain types and naming conventions
   - Existing testing patterns and what paradigms are already in use
   - Any related types or transformations this feature extends or composes with
4. Identify: what raw input enters the system, what final output exits, and what intermediate states
   exist between them.

### Phase 2: Consider Alternatives

First, state the properties the design is scored against. Where `/discuss` produced a target
properties list, carry it forward and translate each into what it demands of the types. Do not
re-derive it. Where none exists, derive it here from what the code will actually do, and name what
observes each property that binds: a type, a test, an assertion, a check against recorded state, or
a measurement that already exists. A property nothing observes is a gap for Phase 5 to close or to
escalate, never one carried forward on trust.

Then sketch 2–3 meaningfully different type progressions for the same feature. For each, state:
- The shape of the progression (a one-line summary of the type structure)
- How it scores against each target property, and which properties it fails to deliver
- Its main tradeoff

Then recommend one, naming the property that decides it. Implementation effort is a constraint,
never a merit: "fewer types", "less refactoring" and "a smaller diff" describe what an option costs
and never why it wins. Only carry the recommended design forward.

### Phase 3: Design the Type Story

Map the full progression of types from input to output in domain terms:

```
Input: <RawType>
  ↓ <transformName>()
<IntermediateType> { field: DomainType, ... }
  ↓ <transformName>()
<FinalType> | <ErrorVariant> | <AlternativeOutcome>
```

For each step:
- **Name the type in domain language** — not implementation language (`Map<String, Any>`,
  `ProcessedData`, `Result2` are all wrong). A reader should understand what this type represents
  from its name alone.
- **State what becomes impossible after this step** — what invalid states the type structure rules
  out that the previous type permitted.
- **Flag anything that requires runtime validation** — where the type system can't enforce a
  constraint and a check is needed instead.
- **For each error or failure variant, name what is retained at that point** — the values someone
  would need to reconstruct the input that produced it. `correctness.md` asks for deterministic
  behaviour so that a failure can be replayed, and replay also needs the input to still exist.
  Where it would not, that constrains the type: an input consumed as a stream cannot be replayed
  and a retained value can, so the choice belongs here rather than at implementation time.

The following are common ways a type story fails. This list is illustrative, not exhaustive — use
your judgment. Any design that fails to tell the domain story in types is wrong, whether or not the
specific failure appears here:
- A step returns the same type it received — the transformation is invisible to the type system
- A type name that would require a comment to explain its domain meaning
- Invalid states at a given stage remain representable when structure could exclude them
- Error types that are too broad — a single `Error` or `Failure` variant where named variants would
  identify which step failed and why
- Types that cross layer boundaries — a persistence-layer type appearing in domain logic, or a
  domain type leaking into a serialisation layer

### Phase 4: Derive the Assertion Plan

The assertion standards live in `~/.agents/standards/correctness.md` and are not restated here.
Read them before this phase; this phase turns them into an artifact.

Where types check structure, assertions check logic and state on every execution, including in
production. For each constraint the type story flagged as needing a runtime check, decide which of
four mechanisms owns it:

1. **Boundary validation** — something outside the code can violate it: absent config, malformed
   input, a failed call, a human editing the content it reads. Belongs in a schema or parser at
   the I/O boundary, returning an error rather than halting.
2. **Assertion** — only a bug in this codebase can violate it. Belongs at the site of the
   contract: preconditions on arguments, postconditions on returns, invariants on internal state.
3. **Recorded-signal check** — only a bug in this codebase can violate it, but no single call site
   can evaluate it, because the invariant spans processes, spans time, or holds over many
   executions rather than one. Every accepted job eventually reaches a terminal state; the number of
   rows written equals the number of events consumed; a cache agrees with its source. The check is
   still an assertion and still follows the standards above, but the site it belongs at does not
   exist yet, so the design creates it. State four things: the invariant, the record the check reads
   and where that record is written, where the check runs (a reconciliation pass, a periodic
   verifier, a comparison of two counters), and what a firing means.

   Such a check records and alerts rather than halting, and that is not a weaker assertion.
   `correctness.md` requires a halt because an assertion fires between computing wrong output and
   using it, so stopping prevents the consequence. A check that runs after the fact has no such
   moment: the output is already out, nothing is prevented by stopping, and halting the verifier
   stops the next check from running as well. What this check owes is a signal a person acts on.
4. **Test only** — none of the above applies.

Destination 3 belongs in the artifact only when a constraint from Phase 3 actually lands there.
Most slices have none, and inventing one to fill the section is worse than leaving it out. It
covers correctness alone: log formats and levels, span and metric naming, latency, cost, capacity,
and dashboard layout are outside this plan even when the same instrumentation would carry them.
Those are implementation concerns, governed by `~/.agents/standards/observability.md`.

A constraint in category 1, 2 or 3 is asserted **and** tested, never asserted instead of tested. A
test covers the inputs its author imagined; an assertion covers the inputs production supplies.
The two find different bugs, and the second kind is why an assertion multiplies the value of
fuzzing and property testing.

State for each assertion: the condition, the site, and whether it pins the positive space (what
must hold) or the negative space (what must never occur). Where both are meaningful, cover both.
Asserting the contract without its breach checks half of it.

Common ways an assertion plan fails:
- An assertion standing in for boundary validation, firing on external input a user can
  legitimately get wrong
- A constraint routed entirely into tests when it could have run against real data
- Assertions that abort on improbable-but-valid states rather than impossible ones
- Several conditions bundled into one assertion, so a failure reports that something broke
  without reporting which
- An invariant that spans executions routed to "test only", where the only thing that ever checks
  it is data a test author made up
- A recorded-signal check specified without naming the record it reads, which leaves it
  unimplementable

### Phase 5: Derive the Telemetry Plan

Types, assertions and tests each verify a property somebody named in advance, so between them they
cover the failures that were predicted. When the system misbehaves in a way nobody anticipated, none
of them fires and what remains is whatever it recorded. This phase decides what that is.

Work from questions, not from emissions. For each step in the type story and each failure variant,
ask what someone will need to know when this behaves wrong at three in the morning, then ask whether
the running system can already answer it. A question it can answer produces nothing here. A question
it cannot answer names one thing to record, and the entry states the question rather than the log
line, so a later reader can tell when the record stops being worth keeping.

Three sources of questions, beyond those the type story suggests on its own:

1. **What each failure variant retains.** Phase 3 named this per variant, because it constrains the
   types. Carry those forward rather than re-deriving them, and check that what is retained answers
   the question somebody would actually ask, not merely that something was retained.
2. **What a recorded-signal check reads.** Phase 4 named a record for every constraint routed to
   destination 3. Those are telemetry decisions already taken, so state them here too and keep the
   two plans from drifting.
3. **A branch the inputs and outputs do not reveal.** Where the code chose between paths and an
   observer holding the input and the output cannot tell which it took, the choice is recorded. This
   is the case neither of the others catches, because nothing failed.

State for each entry: the question, why the system cannot answer it today, and the smallest thing
that would let it. Where the answer needs a mechanism this slice does not own — an identifier that
crosses interfaces, a store that outlives the run — name it as an open decision and stop there. A
slice that invents a system-wide mechanism from the inside produces the third incompatible one, and
`/discuss` is where those are settled.

This plan covers what must be recorded and why. Log format, log levels, field naming, and keeping
telemetry out of the logic it instruments are implementation concerns governed by
`~/.agents/standards/observability.md`, and they do not appear here.

Common ways a telemetry plan fails:
- An emission listed without the question it answers, so nothing says when it could be removed
- A question the system can already answer, restated as a gap
- Retention carried from Phase 3 without being checked against a question, so a variant retains a
  value nobody would ask for
- A system-wide mechanism invented inside one slice rather than escalated
- The plan growing because the section exists; a slice whose behaviour is fully visible in its
  inputs, outputs and exit code has nothing here and says so

### Phase 6: Derive the Test Plan

From the type boundaries, identify what needs behavioral verification. Constraints Phase 4
assigned to an assertion, to boundary validation, or to a recorded-signal check still appear here,
with the pairing named, so that none of them is mistaken for full coverage on its own. Where Phase 5
named a question the running system cannot answer and this slice cannot make answerable, the
behaviour behind it is a candidate for heavier coverage, since production will not report it. For
each transformation:

1. **Compiler guarantees** — list what correct code gets for free from the type design. No tests
   needed for these.
2. **Everything else** — for each behavior the types don't enforce, choose the paradigm that best
   verifies it. Do not default to example-based unit tests. Actively consider whether another
   paradigm provides stronger or cheaper coverage:
   - **Property tests** — when an invariant must hold for any valid input, not just selected examples
   - **Fuzz tests** — when the input space is large and adversarial or malformed inputs are a concern
   - **Snapshot / golden-file tests** — when the output is complex and detecting unexpected change
     matters more than specifying the exact value
   - **Contract tests** — when this component is consumed by others and the interface is a shared
     commitment
   - **Mutation tests** — when you want confidence that the test suite would catch logic errors
   - **Integration tests** — when behavior is only meaningful across multiple layers together
   - **Example tests** — when none of the above apply, or when a specific edge case is important
     enough to document by name

   When Phase 4 assigned assertions to the code under test, weight the choice toward a
   generated-input paradigm where one fits. Each generated case exercises those assertions as well
   as the stated property, so the cheapest way to cover an asserted invariant is often to point a
   generator at it rather than write an example per case.

   For each test case, state what it verifies in domain terms, why the type system doesn't cover
   it, and which paradigm is most appropriate and why.

### Phase 7: Present and Stop

Present the design artifact:

1. **Target properties** — what the design must deliver, carried from `/discuss` or derived in
   Phase 2, and which of them the type system can enforce
2. **Alternatives considered** — the progressions sketched in Phase 2, each scored against those
   properties, and the property that decided the choice
3. **Type story** — the full progression with domain-named types at each step and what each step
   rules out
4. **Compiler guarantees** — what the type design enforces for free
5. **Assertion plan** — which constraints are asserted and where, which are left to boundary
   validation, and which states are deliberately allowed rather than asserted against. Where a
   constraint is checked against a recorded signal, name the record, the check, and what a firing
   means; omit this part entirely when no constraint landed there
6. **Telemetry plan** — the questions the running system cannot answer, what each one needs
   recorded, and what this slice deliberately leaves unobservable; omit it when the slice's
   behaviour is fully visible in its inputs, outputs and exit code
7. **Test plan** — what needs verification, which paradigm, and why
8. **Open decisions** — any naming or structural choices the user should weigh in on before
   implementation begins, including any mechanism Phase 5 found this slice does not own

Ask for explicit approval.

If the user pushes back, requests changes, or raises questions: incorporate the feedback, revise
the type story and/or test plan, re-present the full artifact, and stop again. Do not implement
until the user gives explicit approval.

When the user approves, the implementing agent must record the agreed approach before reading or
writing any files — add a comment to the known ticket (Jira, GitHub issue, Linear, etc.) if one
exists, or create a Trekker task if no ticket exists. Then proceed with the first slice.
