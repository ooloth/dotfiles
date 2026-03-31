---
name: conventions-for-architecture
description: Preferred architecture patterns when not otherwise specified by the project.
---

## Clear boundaries

- Aim to make the boundaries between one concern and another explicit in the codebase to avoid a tangle of interdependencies
- When possible, aim to provide a clear entrypoint/interface/api within the codebase for other codebase components to call when they need what the other component provides
- Be inspired by ideas like hexagonal architecture (ports and adapters), vertical slice architecture (feature folders), but do not follow any of them strictly - the point is to ensure dependencies within the codebase are clear and minimized

## Vertical slices (feature folders)

- When feasible, prefer the ideas underlying feature folders / vertical slices / screaming architecture over layered/tiered approaches
- Optimize for findability (e.g. a human can find everything they need to touch when making a change by searching the file system for a folder/file named for that feature), updatability (related code is grouped cohesively and distant coupling is avoided) and deletability (deleting a folder is all or nearly all that's required to remove a behaviour)
- Aim to avoid human confusion about where to add new code by making the folder structure of the project very obvious and oriented around use cases rather than technologies

## Pipelines

- When feasible, think of features as pipelines with I/O at the outer edges and a composition of pure functions in the middle
- The more I/O can be pushed to the edges, the easier it will be for the core of the codebase to be expressed as meaningful domain objects that flow through transformations that are easy to test
- This doesn't have to mean following FP patterns - but aim to make the code easier to reason about by minimizing the complexity introduced by dependencies on internal state, time, etc
- If it's possible to express a code path as I/O -> transformations -> I/O, strongly consider doing it

## Domain modeling via types

- Use the type system to explain the components of the code base and how they interact
- Prefer domain-specific types over primitive types
- Function signatures can be just as expressive as OOP-style classes for expressing the domain and intent of the code; mix and match those paradigms as needed

## Input Validation Rules

Parse at the I/O boundary and transform raw data into ergonomic, expressive, type-safe domain objects

### Parse real-world data at the I/O boundary

- Don't trust the assumed shape of data arriving from the outside the codebase
- This includes data from SDKs, APIs, config files, environment variables, etc
- Parse the incoming data as a way to (1) validate it and (2) persist the outcome of the validation via the type system
- Aim to resolve all "what is this? what is missing? what operations are safe?" questions so they don't need to be asked again after this step
- In Python, use Pydantic for this
- In JS/TS, use Zod

### Transform parsed API types into ergonomic domain types

- After parsing the incoming data, consider how to reshape it to better express its role in the domain
- In domain terms, what does this represent? Which properties can be discarded? Renamed? Unnested for easier lookups?
- The internal domain object does not have to match the shape of the outer world object
