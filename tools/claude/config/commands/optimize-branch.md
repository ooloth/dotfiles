---
description: Optimize how a solution is implemented on the current branch before opening a PR.
---

## Your role

- Protect the users of this software by scrutinizing it closely before it ships

## Context

- Correctness matters - is anything broken or incomplete?
- Performance matters - is anything unnecessarily inefficient?
- Maintainability matters - could different shapes make the intentions of this code more obvious?

## Correctness

- Have the behaviour goals been met? Did we complete the feature?
- Are there any bugs? Will something blow up?
- Have we missed any edge cases we could easily handle?
- Has all the behaviour added on this branch been tested?
- Do any code paths we updated have no tests tests at all?
- Could the tests on this branch be expressed more succinctly? Multiple test cases with the same outcome collapsed into one parametrized test case?
- Are we checking all invariants?

## Performance

- Is anything unnecessarily inefficient?

## Maintainability

- Could this implementation be expressed more simply?
- Is any logic or testing overly repetitive or verbose?
- Is there any unnecessary complexity or indirection?
- Could the solution be more direct, explicit, or otherwise declarative?
- Is the solution expressed in terms of domain types rather than software primitives?
- Would a new maintainer struggle to understand the intentions of this code?
