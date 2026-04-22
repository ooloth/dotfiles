# Architecture

## Ideal state

### Clear boundaries

- Make boundaries between concerns explicit to avoid a tangle of interdependencies
- Provide a clear entrypoint/interface/API within the codebase for other components to call
- Be inspired by hexagonal architecture (ports and adapters) and vertical slice architecture (feature folders) — not to follow them strictly, but to ensure dependencies are clear and minimized

### Input validation at I/O boundaries

- Parse all incoming data at the I/O boundary; don't trust the assumed shape of data from SDKs, APIs, config files, environment variables, etc.
- Validate and transform raw external data into ergonomic, expressive, type-safe shapes — resolving all "what is this? what is missing? what operations are safe?" questions once, so they don't need to be asked again
- After parsing, consider reshaping to better express the data's role in the domain; the internal domain object does not have to match the outer world's shape
- Python: use Pydantic; JS/TS: use Zod

### Vertical slices (feature folders)

- Prefer feature folders / vertical slices / screaming architecture over layered/tiered approaches
- Optimize for findability (everything needed for a change lives in one folder), updatability (related code is cohesive), and deletability (removing a folder is nearly all that's needed to remove a behaviour)

### Features as pipelines of pure functions

- Think of features as pipelines: I/O at the outer edges, pure function composition in the middle
- Push I/O to the edges so the core is expressed as domain objects flowing through easy-to-test transformations
- If a code path can be expressed as I/O → transformations → I/O, strongly prefer that shape

### Type-driven design and domain modeling

- Use the type system to explain components and how they interact
- Use types to enforce invariants (e.g. `UnvalidatedEmail` in → `ValidatedEmail` out)
- Prefer domain-specific types over primitives

### Make bad states unrepresentable

- Prevention is better than detection — replace boolean flag combinations with finite state machines, replace runtime checks with types that block unwanted values at compile time

## Common failure modes

- Import patterns that suggest poor boundaries or tangled module organization
- Business logic mixed with I/O rather than pushed to the edges
- Patterns that make it difficult to add or remove features safely as the system evolves
- Missing validation at I/O boundaries — untrusted external data flowing into the system unvalidated
- Primitive obsession — raw strings/ints/dicts where domain types would express intent more clearly
- Code that does not represent a good example for humans or future agents to follow
