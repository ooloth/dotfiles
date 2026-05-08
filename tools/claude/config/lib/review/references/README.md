# Review References

Shared heuristics for code writing and code reviewing skills. Each file covers
one category and states invariants — facts about what correct code looks like.

Read this file before any category file.

## How to read the tiers

**Must** — no exceptions. A violation is always wrong. Writing skills never
produce this. Reviewing skills flag it immediately regardless of context.

**Should** — true by default. A violation is wrong unless there is a documented,
deliberate reason for it. Writing skills follow this unless they can name the
exception. Reviewing skills flag violations and ask whether the exception applies.

**Consider** — worth raising for judgment. Neither right nor wrong by default.
Writing skills think about it. Reviewing skills surface it when the tradeoff
seems unresolved.
