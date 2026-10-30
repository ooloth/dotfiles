---
name: uphold-project-invariants
description: Load this repo's own invariants, standards and accepted decisions (docs/invariants/, docs/standards/, docs/decisions/) and apply them to the current task. ALWAYS invoke before designing, writing, or editing ANY code.
---

## Your task

1. Read `docs/invariants/README.md` to understand what qualifies as an invariant in this repo.
2. List `docs/invariants/` and `docs/standards/`, then load every file whose theme is relevant to
   the current task. When in doubt, load it — a false positive costs one read; a false negative
   means a missed constraint.
3. Apply the two differently:
   - **Invariants** hold unconditionally. Violating one means the system is broken, not merely
     unconventional. There is no exception to weigh — if the task appears to require violating an
     invariant, stop and raise it rather than proceeding.
   - **Standards** are graded Must/Should/Consider. A Must has no exception; a Should has
     sanctioned ones, so name the exception if you take it; a Consider is a judgment call with no
     default.
4. List `docs/decisions/`. Each title states what is now true, so the listing shows which choices
   are settled. Read every accepted record that names a file, folder or tool the task changes or
   that a design for it would choose between, including its **Rejected** section and every
   addendum. An option a record rejects stays rejected until the record is amended: when the task
   seems to need it, stop and raise the conflict, naming the record and the reason it gave, rather
   than proceeding.
5. If any of these directories is missing or empty, say nothing about it and carry on.
6. If you notice a gap — something this repo clearly depends on that none of them records —
   mention what should be added. If no gap, say nothing.
7. Proactively apply what you loaded.

This skill covers only what is specific to this repo. Portable engineering guidance lives in the
global `uphold-standards` skill, which loads separately.
