# Code Style Rules

## Readability

- Explicit and obvious is better than clever and terse
- Declarative is better than imperative; don't make human's compute code line by line in their heads to (hopefully) deduce out what its doing and why it would want to do that - make those things explicit
- Encapsulate behaviour in well-named chunks (e.g. helper functions) that summarize what the code is doing
- Prioritize easy onboarding for future humans by making the intentions of the code as obvious as possible
- Mix and match from any paradigm (OOP, FP, etc) based on what would express the intentions of a given code path as clearly as possible

## Comments

- Comment the "why" generously for future maintainers
- Minimize comments that paraphrase the "what" - those comments aren't banned, but try to achieve their goal by making the code itself more explicit and self-documenting
