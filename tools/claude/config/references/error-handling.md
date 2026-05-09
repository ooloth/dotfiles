# Error Handling

Errors are handled well when they are represented in types, enriched as they
travel, and resolved at the level where there is enough context to act on them.

## Must

**Errors are represented in the type system.**
Where the language supports it, fallible operations return Result, Option, or
an equivalent typed error rather than throwing exceptions or returning sentinel
values. Callers cannot ignore an error without explicitly choosing to.

**Error context is preserved as errors propagate.**
When an error crosses a boundary or moves up the call stack, it is wrapped with
context that explains what the caller was trying to do. A chain of wrapped
errors reads as a narrative, not a raw exception.

**Internal details are not exposed to external callers.**
Stack traces, internal paths, database messages, and implementation details
are logged internally and stripped from responses to callers. What a caller
receives tells them what failed, not how the system is built.

## Should

**Errors are handled at the level with enough context to act.**
An error is not caught and swallowed deep in a call stack where nothing
meaningful can be done. It propagates until it reaches a layer that can
recover, retry, degrade gracefully, or surface a useful message.

**Domain errors and programming errors are distinct.**
Expected failures (not found, validation failed, quota exceeded) are modeled
as domain errors. Unexpected failures (nil dereference, assertion violation)
are programming errors and are not caught and handled as if they were expected.

**User-facing messages are actionable.**
When an error reaches a user, the message describes what failed and, where
possible, what to do next. "Something went wrong" is not a user-facing message.

## Consider

**Errors are aggregated where multiple can occur.**
When validating input or processing a batch, all errors are collected before
returning rather than failing on the first. Callers receive a complete picture.
