# User Experience

A system has sound UX when users can accomplish what its stated purpose
implies they should be able to, understand what happened when something goes
wrong, and discover what is available without needing to ask.

This applies to whatever interfaces the system exposes — CLI, API, UI, or
otherwise. UX is not a visual or platform concern; it is a usability concern.

## Must

**The system's purpose is stated from the user's perspective.**
Before a user invokes anything, they understand what the system does for
them. The first thing they read answers "what will this help me do?" not
"what is this built with?"

**Errors are actionable.**
When something goes wrong, the message tells the user what failed and, where
possible, what to do next. "Something went wrong" is not an error message.
An error message that reproduces the internal exception without user-friendly
context is not an error message. The user should be able to act on what they
read without searching for the cause.

**Critical workflows are completable end-to-end.**
The system does not leave users stranded partway through a task it implies
it supports. If the system advertises a capability, a user can exercise that
capability from start to a useful result without hitting an unhandled state.

## Should

**Public interfaces have discoverable help.**
A user can find out what the system offers without reading source code.
CLI commands expose `--help`. APIs have documentation. The system's
surface area is not a secret.

**The path from first contact to first success is short and documented.**
A new user can accomplish a useful task without asking for help. The steps
are written down and current. A user who follows them arrives at a working
result, not a dead end.

**Long-running operations provide feedback.**
When the system is working, the user knows it. Progress is visible. The user
is not left wondering whether the process has stalled.

**Interface conventions are consistent.**
A user who learns one part of the interface can predict how other parts
behave. Flags, parameters, response shapes, and terminology follow a single
convention throughout.

## Consider

**Common workflows have examples.**
Not just documentation of what is possible, but demonstrations of how. A
user can copy an example and adapt it rather than composing a workflow from
first principles.

**Edge cases produce helpful output.**
Unexpected or invalid inputs are met with messages that explain what was
wrong and what is expected — not crashes, panics, or silent failures.

**The system distinguishes transient from permanent failures.**
When a failure is retryable, the user is told so. When a failure requires a
different action, the user is told what action. The user does not have to
guess whether trying again will help.

## In scope

- CLI commands and their help text and error output
- API endpoints and their response bodies, status codes, and error shapes
- User-facing documentation, tutorials, and examples
- Onboarding materials and getting-started guides

## Out of scope

- Internal error handling not visible to users (covered by error-handling)
- API contract correctness and stability (covered by api-design)
- CLI flag naming and structural conventions (covered by cli-design)
- Visual design and rendering concerns specific to a UI framework
