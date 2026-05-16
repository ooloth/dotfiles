# Project Harness

A project's harness is sound when an agent encountering it for the first time
can understand its purpose, verify its own work by observing the running
system, and know what constraints govern its decisions — without asking the
author.

## Must

**A project context file exists and states what the project builds and why.**
`CLAUDE.md`, `AGENTS.md`, or an equivalent file is present at the repo root.
An agent reading only that file understands the system's purpose, domain, and
the problem it solves. The file is not a changelog or a setup guide — it is
an orientation document.

**How to run the project's checks is documented or discoverable.**
The commands to run tests, linting, type checking, and builds are stated
explicitly or reachable from a standard entry point. An agent can verify its
changes without asking what to run.

**Non-obvious constraints are stated explicitly.**
Gotchas, forbidden patterns, intentional deviations from convention, and
decisions that would surprise a competent agent are written down. An agent
should not have to discover these by making mistakes.

**A documented way to invoke the running system locally exists.**
The agent can exercise real code paths — not only run tests. A CLI command,
script, or documented invocation sequence lets the agent observe what the
system actually does, not only what tests assert it should do.

## Should

**Usage patterns are described.**
How users or callers interact with the system is documented. An agent
understands the intended interaction model — what inputs the system accepts,
what outputs it produces, and what a typical session looks like.

**Key domain concepts are defined.**
Terms, entities, and relationships that a general-purpose agent might
misunderstand or map incorrectly to general programming concepts are
explained. An agent that misunderstands the domain will make plausible but
wrong decisions.

**Non-obvious architectural decisions are recorded with rationale.**
When the structure of the codebase reflects a deliberate tradeoff — a chosen
pattern, a rejected alternative, a constraint imposed by context — the reason
is written down. An agent that understands the why is less likely to
accidentally undo it.

**Agent tool permissions are explicitly configured.**
The harness states what operations are permitted and disallowed — file paths
the agent should not touch, commands it should not run, external systems it
should not call. Explicit configuration is more reliable than convention.

**The harness surfaces check failures automatically during agent sessions.**
When an agent's changes break a test, fail a lint rule, or violate a build
constraint, the failure is visible to the agent in the same session without
requiring human intervention. The mechanism — hooks, a mandatory check step,
a CI result the agent is instructed to read — is not prescribed; what matters
is that the agent can observe and self-correct.

**Observability signals are documented and discoverable.**
Logs, traces, and metrics the system emits are described: where they appear,
what format they use, and what the key fields mean. An agent should not need
to grep source code to discover that signals exist or to understand what they
say.

**The signals are rich enough to diagnose failures from the outside in.**
When a code path misbehaves at runtime, an agent reading logs or traces can
identify the cause without reading implementation code. This is the critical
distinction from tests: tests validate what the author thought to check;
runtime signals reveal what actually happened. Sparse or unstructured signals
force the agent back to static analysis, losing the validation power of a
running system.

**The agent is told how to trigger specific code paths.**
Beyond "run the test suite", the harness documents how to exercise particular
behaviours — "to test the auth flow, invoke X; to verify cache behaviour,
do Y." This lets the agent validate a hypothesis empirically rather than
only statically.

## Consider

**The project's maturity is indicated.**
An agent should know whether it is working on a prototype, an internal tool,
or a production system. That context changes how aggressively Should
violations should be treated and how much churn is acceptable.

**Health check or status commands are documented.**
A quick invocation the agent can run to assess overall system state — before
and after a change — is described. A health check provides a fast outside-in
signal that the system is behaving normally.

**Representative output is documented.**
Example log lines, trace snippets, or metric values under normal conditions
are recorded. An agent that has never run the system can recognise a normal
signal versus an anomalous one without needing to run it first.

**External integrations and non-obvious runtime dependencies are catalogued.**
Services, APIs, or environment conditions the system depends on at runtime
are listed. An agent that doesn't know a dependency exists cannot account for
its absence or failure.

**Cross-harness compatibility is maintained.**
If agent tools other than the primary harness are used alongside it, their
config files are symlinked to the canonical equivalents rather than
maintained separately — for example, `AGENTS.md` → `CLAUDE.md` and
`.agents/skills` → `.claude/skills`. A single source of truth prevents the
two from drifting.

## In scope

- `CLAUDE.md`, `AGENTS.md`, and any equivalent project context files
- `.claude/`, `.agents/`, and equivalent harness config directories
- `README.md` at the repo root
- Files under `docs/` or equivalent documentation directories

## Out of scope

- Production monitoring dashboards not accessible during local development
- Observability infrastructure the project does not own or configure
- Third-party tool configuration files unrelated to agent interaction
