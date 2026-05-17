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

1. Read the agreed objective from $ARGUMENTS — if it's a Trekker task number, read that task; if it's
   a description, use it directly. Ask the user to clarify if the scope is still ambiguous.
2. Load `~/.claude/references/type-design.md` and `~/.claude/references/testing.md`.
3. Explore the codebase to understand:
   - Existing domain types and naming conventions
   - Existing testing patterns (what level of test is used where, property vs. example vs. integration)
   - Any related types or transformations this feature extends or composes with
4. Identify: what raw input enters the system, what final output exits, and what intermediate states
   exist between them.

### Phase 2: Design the Type Story

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

The type story is wrong if:
- Any step returns the same type it received — the transformation is invisible to the type system
- Any type name would require a comment to explain its domain meaning
- Invalid states at a given stage remain representable when they could be excluded by structure

### Phase 3: Derive the Test Plan

From the type boundaries, identify what needs behavioral verification. Work through each
transformation:

1. **Compiler guarantees** — list what correct code gets for free from the type design. These need
   no tests.
2. **Example tests** — specific inputs and expected outputs at boundary conditions, error paths, and
   cases where the same type can mean different things.
3. **Property tests** — invariants that must hold for any valid input of a given type; worth using
   when the space of valid inputs is large or the invariant is non-obvious.
4. **Integration tests** — behaviors that require multiple layers to exercise meaningfully.

For each test case, state:
- What it verifies in domain terms (not implementation terms)
- Why the type system doesn't already cover it
- What kind of test is appropriate and why

### Phase 4: Present and Stop

Present the design artifact:

1. **Type story** — the full progression with domain-named types at each step and what each step
   rules out
2. **Compiler guarantees** — what the type design enforces for free
3. **Test plan** — what needs verification, what kind of test, and why
4. **Open decisions** — any naming or structural choices the user should weigh in on before
   implementation begins
5. **Approval request** — ask the user to approve the design

Do not implement. When the user approves, the implementing agent must create or update a Trekker
task before reading or writing any files, then proceed with the first slice.
