# Code Style

## Ideal state

### Readability

- Make the intention of each code path obvious via expressive function and type names
- Encapsulate behaviour in well-named chunks that summarize what the code does
- Explicit is better than clever; declarative is better than imperative — it should not be necessary to read a function body line-by-line to infer what it does

### Maintainability

- Capture repeated hard-coded values in a reused constant or enum
- Keep files under 2000 lines — the Read tool silently truncates at 2000 lines, creating a blind spot for agents doing code review, refactoring, or analysis

### Testability

- Prefer pure functions to make domain decisions easy to test
- Isolate I/O at the edges and extract the pure centre into helpers the main entrypoint orchestrates
- Minimize the need to mock, fake, patch, or test indirectly — enable calling real objects directly

## Common failure modes

- Clever code that requires reading line-by-line to understand
- Files over 2000 lines
- Hard-coded values repeated across multiple sites that should be a shared constant or enum
- I/O interleaved with logic, making the logic hard to test in isolation
- Inconsistent patterns for a category that has no defined convention — note what convention might be worth defining
