# Code Structure

A codebase is well-structured when components know only what they need to,
dependencies and data both flow in one direction, and boundaries between
components are as narrow as the problem allows.

## Must

**Dependencies flow in one direction.**
Dependency cycles don't exist. A component depends on what's below it in the
stack; nothing below depends on something above. Import direction is enforced,
not trusted.

**Implementation details don't cross boundaries.**
What belongs inside a component stays inside it. Types, functions, and data
structures that are implementation details are not imported by other components.
Only types that belong to the interface cross.

**Side effects live at the edges.**
I/O, external API calls, and mutation of shared state happen at entry and exit
points. Business logic in the middle is free of I/O and can be reasoned about
and tested without external dependencies.

## Should

**Orchestration is separated from execution.**
Coordination logic — deciding what to do, validating preconditions, sequencing
steps — is kept separate from the code that does the work. Mixing them forces
execution paths to pay coordination costs on every iteration and makes either
harder to test in isolation.

**Public surfaces are as small as possible.**
A component exposes only what callers need. Every additional export is a
commitment to maintain. Internal details are private by default.

**Callers depend on interfaces, not implementations.**
When a boundary exists, callers depend on the contract it defines, not the
concrete type behind it. Swapping implementations doesn't require changing
callers.

**Data flows in one direction.**
State transformations move forward through the call stack. Callbacks, circular
references, and shared mutable state are avoided where a simple pipeline
would do. Bidirectional data flow between components is a structural smell,
not just a readability one.

**Boundaries and files are named after domain concepts.**
Module, package, directory, and file names correspond to problem-domain
concepts, not implementation mechanics. `payment/`, `subscription/`,
`invoice.ts` are domain names. `utils/`, `helpers/`, `types.ts`, `hooks.ts`,
`store.ts`, `api.ts` used as aggregates are layer names — they describe how
the code is built, not what it does.

**Code is organized by feature, not by layer.**
Related types, logic, and I/O for a feature live together. A change to one
feature touches one folder, not five. Adding a feature means adding a folder;
removing a feature means deleting one.

**The directory tree is navigable without reading code.**
A developer unfamiliar with the codebase can locate the relevant file for a
domain concept by reading directory and file names alone — without tracing
imports, grepping, or asking. When the tree requires code reading to
navigate, the names or structure are wrong.

## Consider

**New boundaries are justified.**
Before introducing a new component, the cost — a new interface to maintain, a
new dependency to manage — is weighed against the benefit of the separation.

## In scope

- Import and use statements across all source files
- Module, package, or crate boundary definitions
- Directory structure and file naming
- Manifest files defining package or workspace structure

## Out of scope

- Test code that imports broadly for fixture or integration-testing purposes
- Dev-only or build-only dependencies
