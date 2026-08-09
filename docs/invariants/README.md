# Invariants

Facts that are true only because of a choice specific to _this_ system's
domain — not portable engineering advice, which lives in `docs/standards/`
instead.

## What belongs here

- A property that holds unconditionally for this repo's actual behavior,
  verified against the current code, not aspirational documentation
- Violating it means something is broken or inconsistent with what the
  rest of the system depends on — not merely "unusual" or "off-convention"
- True because of a decision made for this specific domain — would not
  necessarily be true of any other codebase

## What doesn't belong here

- **Graded guidance with legitimate exceptions** (Must/Should/Consider
  content) — belongs in `docs/standards/`. An invariant has no sanctioned
  exception; if it has one, it's a standard, not an invariant.
- **API documentation for a specific function or type** — belongs as a doc
  comment at the definition site. "This helper's second argument is a
  directory" is documentation, not a system-level truth.
- **Frequency statistics or typical-practice observations** ("most tools
  don't need X") — these describe what's common, not what must hold. A
  true invariant doesn't get less true because most cases don't exercise it.

## The test

Before adding a line here, ask: if this were violated, would the system be
broken — or just inconsistent with how most people happen to do it? Only
the former belongs.
