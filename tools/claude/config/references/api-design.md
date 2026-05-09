# API Design

An API is well-designed when callers can use it correctly without reading its
implementation, cannot easily use it incorrectly, and are not broken by changes
to what's behind it.

## Must

**Contracts are expressed in types.**
Inputs, outputs, and errors are typed. A caller knows what an operation accepts
and returns without reading its body. Untyped or stringly-typed interfaces
don't exist where the type system can express the contract.

**Breaking changes are versioned and communicated.**
When a public interface changes in a way that breaks existing callers — a
removed field, a renamed operation, a changed type — that is identified,
versioned, and communicated before it ships. Silent breakage doesn't ship.

**Naming is consistent within an API surface.**
Operations, fields, and parameters follow one convention throughout. A caller
who learns one part of the API can predict the shape of the rest.

## Should

**APIs are designed from the caller's perspective.**
The shape of the interface reflects what callers need to express, not what is
convenient for the implementation. Callers don't pass internal IDs, reconstruct
state, or work around implementation details.

**Operations are idempotent where possible.**
Mutations that can be made safe to repeat are. A caller who retries an
operation due to a network failure does not produce duplicate state.

**The public surface is minimal.**
Only what callers need is exposed. Every additional public symbol is a
commitment to maintain. Internal details are hidden by default.

## Consider

**The simple case is simple.**
Common usage requires the fewest inputs and the least ceremony. Advanced
options are available but don't intrude on the common path.

**Errors are part of the contract.**
The failure modes of an operation are as documented as its happy path. A
caller knows what errors to expect and under what conditions.

## In scope

- Exported function and method signatures
- Public type definitions
- REST/RPC route handlers and SDK surface files
- Interface declarations

## Out of scope

- Internal helpers with no external callers
- Test utilities not part of the public API
