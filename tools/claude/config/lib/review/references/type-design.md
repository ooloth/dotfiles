# Type Design

Types carry their weight when they make correct states easy to construct,
incorrect states impossible to represent, and function signatures readable
as a description of the domain.

## Must

**External data is parsed into domain types at the boundary.**
Raw inputs — API responses, CLI arguments, environment variables, file
contents — are converted into domain types at the point of entry. Primitives
don't leak inward. Validation is a side effect of parsing, not a separate step.

**Primitives are not used where domain types express intent more clearly.**
A user ID is not an int. An email is not a str. A status is not a bool. Where
a primitive would require a comment to explain its meaning, a named type is
used instead.

**Invalid states are unrepresentable.**
Types are structured so the compiler or runtime rejects invalid combinations.
Mutually exclusive flags become enums or union types. Optional fields are
expressed in types, not checked at runtime. A value that has been validated
has a different type than one that hasn't.

## Should

**Functions transform types rather than return what they received.**
A function that does meaningful work produces a more specific or different type
than its input. Returning the same type signals that the function's effect is
invisible to the type system — a missed opportunity to encode what changed.

**State transitions are encoded in types.**
When an entity moves through states — unconnected → connected, draft →
published — each state is a distinct type. Operations valid only in a given
state belong only to that type. Invalid transitions are rejected at compile
time, not discovered at runtime.

**Type annotations are complete.**
All function signatures are annotated. There are no implicit or inferred types
at public boundaries. A reader can understand a function's contract without
reading its body.

## Consider

**Pure logic is separated from I/O.**
Code that doesn't require I/O is extracted from code that does. This expands
the surface area that can be tested without mocks or fixtures, and makes
type-level reasoning easier.
