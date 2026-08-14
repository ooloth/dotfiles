# Data Integrity

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

**Related representations stay in sync.**
Denormalized fields, derived counts, and both sides of a relationship are
updated together in the same operation. One side is not updated without the
other.

**Migrations handle existing data.**
Schema changes account for rows that already exist. New non-nullable columns
have a backfill or a default. New constraints are validated against existing
data before being enforced.

**Migrations are reversible.**
A down migration exists and has been thought through. If rollback is genuinely
impossible, that is documented and a compensating path is identified.

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

## Out of scope

- Read-only query code
- Test fixtures that use simplified schemas by design
