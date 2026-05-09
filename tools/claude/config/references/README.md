# References

Shared reference files for code writing and code reviewing skills.

## What these files are

Each file states **invariants** — facts about what correct code looks like,
written in declarative form. Invariants are not instructions to the agent; they
are descriptions of what is true about well-written code.

This framing makes each file usable in two directions without changing the
content:

- A **writing** skill reads an invariant as: "produce code that satisfies this"
- A **reviewing** skill reads an invariant as: "check whether the code satisfies this"

## Read this file first

Always read this file before any category file. The tier definitions below
govern how strongly each invariant should be upheld or flagged.

## Tiers

**Must** — no exceptions. A violation is always wrong. Writing skills never
produce this. Reviewing skills flag it immediately regardless of context.

**Should** — true by default. A violation is wrong unless there is a documented,
deliberate reason for it. Writing skills follow this unless they can name the
exception. Reviewing skills flag violations and ask whether the exception applies.

**Consider** — worth raising for judgment. Neither right nor wrong by default.
Writing skills think about it. Reviewing skills surface it when the tradeoff
seems unresolved.
