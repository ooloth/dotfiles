---
description: Optimize how a solution is implemented on the current branch before opening a PR.
---

## Context

## Implementation

- Have we missed edge cases? Do you see potential bugs? Assume we are aiming for safe, reliable software.
- Could this implementation be expressed more simply without regressions? Unnecessary complexity or indirection is unwanted. Direct, explicit, declarative solutions are preferred. The goal is fewer bugs due to the domain and intentions being clearer. Now is the time to fix this.

## Testing

- Has all the behaviour added on this branch been tested? What gaps do you see? Now is the time to fill them.
- Did we update any code paths with no tests at all? If so - now is the time to add those tests.
- Could the tests on this branch be expressed more succinctly? Multiple test cases with the same outcome collapsed into one parametrized test case?
