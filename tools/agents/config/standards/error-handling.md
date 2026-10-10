# Error Handling

Errors are handled well when they are represented in types, enriched as they
travel, and resolved at the level where there is enough context to act on them.

## Must

**Error context is preserved as errors propagate.**
When an error crosses a boundary or moves up the call stack, it is wrapped with
context that explains what the caller was trying to do. A chain of wrapped
errors reads as a narrative, not a raw exception.

**Internal details are not exposed to external callers.**
Stack traces, internal paths, database messages, and implementation details
are logged internally and stripped from responses to callers. What a caller
receives tells them what failed, not how the system is built.

**Parsing untrusted input before authentication turns every failure into a rejection.**
Code that reads a request before anything vouches for it, such as an
unverified token, a raw header or a request body, catches every exception the
parse can raise, not only the library's own error type, and returns the same
rejection malformed input gets. Libraries raise other types on hostile input:
a JSON decoder raises a recursion error on deep nesting, which an
unauthenticated caller can send in a few kilobytes. Left uncaught, it becomes a
server error and a stack trace for input that should have been refused. The
exception's type name may be logged; the input itself is not.

## Should

**Errors are represented in the type system.**
Where the language supports it, fallible operations return Result, Option, or
an equivalent typed error rather than throwing exceptions or returning sentinel
values. Callers cannot ignore an error without explicitly choosing to.

**Errors are handled at the level with enough context to act.**
An error is not caught and swallowed deep in a call stack where nothing
meaningful can be done. It propagates until it reaches a layer that can
recover, retry, degrade gracefully, or surface a useful message.

**Domain errors and programming errors are distinct.**
Expected failures (not found, validation failed, quota exceeded) are modeled
as domain errors. Unexpected failures (nil dereference, assertion violation)
are programming errors and are not caught and handled as if they were expected.

**Error messages and context use domain vocabulary.**
Errors describe what failed in terms the domain recognises, not in terms of
implementation mechanics. "Payment declined: monthly quota exceeded" is a
domain error. "execute() returned -1" is not. In systems using opaque error
types, context chains (`.context()`, `.with_context()`) serve this role —
each layer adds domain meaning, not stack details.

**User-facing messages are actionable.**
When an error reaches a user, the message describes what failed and, where
possible, what to do next. "Something went wrong" is not a user-facing message.

## Consider

**Errors are aggregated where multiple can occur.**
When validating input or processing a batch, all errors are collected before
returning rather than failing on the first. Callers receive a complete picture.

## In scope

- Fallible operations and error propagation paths
- User-facing error output sites

## Out of scope

- Test code that uses `unwrap()` or equivalent deliberately for assertion clarity
