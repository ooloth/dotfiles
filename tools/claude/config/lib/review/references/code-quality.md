# Code Quality

Code quality is local: names, size, and the absence of noise. A file has high
code quality when any expression or function can be understood in isolation.

## Must

**Dead code is absent.**
Unused imports, variables, functions, and commented-out code don't exist.
Remnants from exploration or abandoned approaches are removed before merging.

**Naming reflects intent.**
Names say what a thing is or does, not how it works or where it came from.
A reader shouldn't need to trace an implementation to understand a call site.

## Should

**Functions are small enough to reason about.**
Long functions are extracted at natural seams. Deeply nested blocks are
flattened or extracted. A function that requires scrolling to read is examined
for natural split points.

**Logic is not clever.**
When a simpler, more direct expression achieves the same result, it is used.
Cleverness that requires a comment to explain is rewritten.

## Consider

**Magic values are named.**
Literal numbers and strings that carry meaning are extracted to named constants.
A reader understands what a value represents without searching for its origin.
