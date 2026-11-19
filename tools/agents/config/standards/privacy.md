# Privacy

Code respects privacy when it collects only what it needs, retains it only as
long as necessary, and treats personal data as a liability rather than an asset.

## Must

**PII is not logged.**
Names, email addresses, phone numbers, identifiers, location data, and other
personal information do not appear in logs, error messages, traces, or
analytics events. Logging is audited when new personal data fields are added.

**Personal data has a stated purpose.**
Data is collected because a specific feature requires it, not speculatively.
If the purpose disappears, the data is deleted.

## Should

**Log redaction runs in the log formatter, the one place every entry passes, rather than at call
sites or in per-library filters, and it never asserts at run time, because a failure inside logging
prints the raw record.**

**Log redaction takes time linear in the length of the text it scans.**
It runs on every entry, under the handler's lock, and a client chooses some of
that text, such as a request path or a value an exception quotes. A pattern
that retries from every position of a long run, such as an unbounded
`[\w.+-]+@` before an address, takes time quadratic in the run's length. Each
part is bounded by the limit its format sets, such as the 64-character local
part and 255-character domain of RFC 5321 §4.5.3.1, and a test times the
redaction on long inputs shaped to make it backtrack. Seen in a
work repo: an unbounded email
pattern took 12.5 s on 64,000 word characters.

**Data collection is minimal.**
The system collects the least personal data needed to deliver its value.
Fields that are not actively used are not stored.

**Retention is bounded.**
Personal data is not kept indefinitely. Retention periods exist, are
documented, and are enforced — either by automated deletion or by periodic
review.

**Deletion is complete.**
When a user's data is deleted, it is removed from all stores — primary
databases, caches, backups where feasible, and downstream systems. Soft
deletes that leave data indefinitely accessible are not a substitute.

**Sensitive data is encrypted.**
Personal data is encrypted at rest and in transit. Encryption is not optional
for fields that would cause harm if exposed.

## Consider

**Privacy is considered at design time.**
Before a new feature collects personal data, the privacy implications are
identified. The question "do we need this?" is asked before "how do we store
this?"

## In scope

- Logging statements
- Error messages and API responses
- Analytics event construction
- Database schemas and model definitions
- API response serialization

## Out of scope

- Data that is not personally identifiable
- Logs written exclusively to secure, access-controlled audit stores
