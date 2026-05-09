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
Names are never abbreviated — `connection` not `conn`, `maximum` not `max`,
unless the abbreviated form is the established domain term.

## Should

**Files are under 2000 lines.**
Files longer than 2000 lines are split at natural seams. The Read tool
truncates silently at 2000 lines, creating blind spots for any agent reading
the file.

**Functions are small enough to reason about.**
Long functions are extracted at natural seams. Deeply nested blocks are
flattened or extracted. A function that requires scrolling to read is examined
for natural split points.

**Logic is not clever.**
When a simpler, more direct expression achieves the same result, it is used.
Cleverness that requires a comment to explain is rewritten.

## Consider

**Related names sort by most significant word.**
When a concept has qualifiers (unit, bound, direction), the concept leads:
`connection_count_max` rather than `max_connection_count`. Related names
align visually and sort meaningfully when listed together.

**Magic values are named.**
Literal numbers and strings that carry meaning are extracted to named constants.
A reader understands what a value represents without searching for its origin.
