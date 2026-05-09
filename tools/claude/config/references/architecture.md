# Architecture

A system's architecture is sound when components know only what they need to,
dependencies flow in one direction, and boundaries between components are as
narrow as the problem allows.

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

**The control plane is separated from the data plane.**
Orchestration, validation, and assertions happen in the control plane. The data
plane executes large batched units of work without interruption. Mixing them
forces the data plane to pay control-plane costs on every iteration.

**Public surfaces are as small as possible.**
A component exposes only what callers need. Every additional export is a
commitment to maintain. Internal details are private by default.

**Callers depend on interfaces, not implementations.**
When a boundary exists, callers depend on the contract it defines, not the
concrete type behind it. Swapping implementations doesn't require changing
callers.

## Consider

**Boundaries reflect the domain.**
Module, package, and service names correspond to problem-domain concepts, not
implementation concerns (utils, helpers, misc). A reader can infer what lives
where from domain knowledge alone.

**New boundaries are justified.**
Before introducing a new component, the cost — a new interface to maintain, a
new dependency to manage — is weighed against the benefit of the separation.

**Code is organized by feature, not by layer.**
Related types, logic, and I/O for a feature live together. A change to one
feature touches one folder, not five. Adding a feature means adding a folder;
removing a feature means deleting one.

## In scope

- Import and use statements across all source files
- Module, crate, or package boundary definitions
- Directory structure
- Cargo.toml / package.json workspace layout

## Out of scope

- Test code that imports broadly for fixture or integration-testing purposes
- Dev-only or build-only dependencies
