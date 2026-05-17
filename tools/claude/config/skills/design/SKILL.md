---
name: design
description: Design the type progression and test plan for approved work. Invoke after agreeing on the high-level approach and before writing any implementation.
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
2. Load `~/.claude/references/type-design.md` and `~/.claude/references/testing.md`. Also load any
   language-specific reference file that applies to this codebase (`~/.claude/references/rust.md`,
   `~/.claude/references/python.md`, etc.).
3. Explore the codebase to understand:
   - Existing domain types and naming conventions
   - Existing testing patterns and what paradigms are already in use
   - Any related types or transformations this feature extends or composes with
4. Identify: what raw input enters the system, what final output exits, and what intermediate states
   exist between them.

### Phase 2: Consider Alternatives

Before committing to a design, sketch 2–3 meaningfully different type progressions for the same
feature. For each, state:
- The shape of the progression (a one-line summary of the type structure)
- What it optimises for (clarity at boundaries, fewer allocations, stronger compiler guarantees,
  simpler error handling, etc.)
- Its main tradeoff

Then recommend one with a sentence explaining the choice. Only carry the recommended design forward.

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

### Phase 4: Derive the Test Plan

From the type boundaries, identify what needs behavioral verification. For each transformation:

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

   For each test case, state what it verifies in domain terms, why the type system doesn't cover
   it, and which paradigm is most appropriate and why.

### Phase 5: Present and Stop

Present the design artifact:

1. **Alternatives considered** — the progressions sketched in Phase 2 and why the recommended one
   was chosen
2. **Type story** — the full progression with domain-named types at each step and what each step
   rules out
3. **Compiler guarantees** — what the type design enforces for free
4. **Test plan** — what needs verification, which paradigm, and why
5. **Open decisions** — any naming or structural choices the user should weigh in on before
   implementation begins

Ask for explicit approval.

If the user pushes back, requests changes, or raises questions: incorporate the feedback, revise
the type story and/or test plan, re-present the full artifact, and stop again. Do not implement
until the user gives explicit approval.

When the user approves, the implementing agent must create or update a Trekker task before reading
or writing any files, then proceed with the first slice.
