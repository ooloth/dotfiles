---
name: conventions-for-code-style
description: Preferred code style across all languages when idiomatic and not otherwise specified by language-specific or project guidance.
model: haiku
effort: low
---

## Readability

- Make the intention of each code path obvious to future humans and agents via expressive function and type names
- Encapsulate behaviour in well-named chunks (e.g. helper functions) that summarize what the code is doing
- Explicit is better than clever
- Declarative is better than imperative - it should not be necessary to read a function body line-by-line to infer what it does

## Maintainability

- Repeated hard-coded values should ideally be captured in a reused constant of some sort (e.g. an enum)
- Keep files under 2000 lines. The Read tool silently truncates at 2000 lines, so an agent reading a longer file will miss everything after that point without any warning — creating a blind spot for code review, refactoring, and analysis tasks. Split large files by extracting cohesive groups of related functions, types, or test cases into new files before they hit that limit.

## Testability

- Prefer pure functions wherever possible to make domain decisions easy to test
- Isolate I/O at the edges and extract the pure centre into one or more pure helpers the main entrypoint orchestrates
- Aim to minimize the need to mock, fake, patch or otherwise test indirectly
- Ideally, code paths will be testable by calling the real objects directly; try to enable that
