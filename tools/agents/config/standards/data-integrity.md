# Data Integrity

<!-- TODO: reframe as data-management to encourage reading more often? -->

Data has integrity when it is valid at the moment it is written, consistent
across all the places it is represented, and recoverable if a write sequence
fails partway through.

## Must

**Invalid data cannot reach persistent storage.**
Validation and constraint enforcement happen before any write. Application-level
checks and database-level constraints agree — one is not a substitute for the
other.

**Multi-step writes are atomic.**
When a logical operation touches more than one record or table, it is wrapped
in a transaction. Partial failure leaves no corrupt intermediate state.

**Concurrent writes are safe.**
Read-modify-write sequences are protected against races. Optimistic concurrency
(version fields, ETags) or pessimistic locking is used where two writers could
collide on the same record.

## Should

**A cache or mirror distinguishes "the source said nothing" from "the source said empty".**
A fetch that reaches no source returns the same shape as one that reaches every source and finds
nothing: an empty collection. Writing the first over a populated store destroys what was known and
asserts a fact nobody observed, and it does so while every individual step reports success. The
write path therefore branches on whether anything was reached, not on whether the result is empty,
and refuses when nothing was. The condition is a conjunction — empty *and* something failed — for
the symmetric reason: a source that genuinely returned nothing is a real answer, and refusing to
record it leaves the store asserting stale rows forever. Unattended writers are where this bites,
because nobody is present to distrust the empty result. The exception worth documenting is a store
whose readers can already tell the two apart, such as one that keeps the failure alongside the
data.

**A value that can be derived is derived, not stored beside its source.**
Completion flags, counts, totals, and cached summaries are computed from the
data they summarise rather than maintained as a second field that can disagree
with it. The most reliable way to keep two representations in sync is to have
one. Storing a derived value is a deliberate trade — made when recomputation
is genuinely too expensive — not the default, and it converts a question with
one answer into two answers that can drift.

**Related representations stay in sync.**
Denormalized fields, derived counts, and both sides of a relationship are
updated together in the same operation. One side is not updated without the
other. This is the obligation taken on by the trade above.

**Migrations handle existing data.**
Schema changes account for rows that already exist. New non-nullable columns
have a backfill or a default. New constraints are validated against existing
data before being enforced.

**Migrations are reversible.**
A down migration exists and has been thought through. If rollback is genuinely
impossible, that is documented and a compensating path is identified.

**A value rejected while loading a row still leaves a way to repair that row.**
A column type, ORM decoder or model hook that raises while loading a row breaks every reader of
that row. That includes the code meant to fix it: a reconnect, overwrite or delete that loads the
row first fails the same way as the read that found the problem. So a check made while loading
takes one of two forms. Either it is lenient and returns a value that the code using it refuses, or
it is strict and its error names a recovery step that does not load the row, such as which row to
delete and how the system recreates it. Strict fits when only a direct edit to the database can
produce the bad value, because a lenient type makes every reader handle a case the system never
produces. The error should also say the system never writes that value, so whoever hits it looks
for the edit rather than a bug in the write path.

## Consider

**Uniqueness is enforced at the database level.**
Application-level uniqueness checks are not used alone. A unique constraint or
index in the database is the backstop, since application checks have race
windows.

## In scope

- Database models and schema definitions
- Migration files
- Write paths and transaction sites
- Read-modify-write sequences
- Column types and ORM decoders that validate on read

## Out of scope

- Read-only query code
- Test fixtures that use simplified schemas by design
