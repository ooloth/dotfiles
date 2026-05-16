# Developer Experience

A project has sound DX when a human developer joining it for the first time
can orient themselves, understand why the system is structured as it is, and
make a confident first contribution without needing to ask anyone.

## Must

**The project's purpose is stated from a developer's perspective.**
README or equivalent explains what the system does, what problem it solves,
and who it is for. A developer reading only that file understands whether
they are in the right place and what the system is trying to be.

**Local setup is documented and complete.**
The steps to get a working development environment are written down. A
developer can follow them cold and arrive at a state where they can build,
run, and test the system. No step requires asking a long-tenured contributor.

**Non-obvious conventions are written down.**
Patterns, constraints, and decisions that would surprise a competent
developer are documented where a new contributor would find them. A developer
should not have to discover conventions by having their PR rejected.

## Should

**Domain concepts are defined.**
The core terms, entities, and relationships of the problem domain are
explained. A developer who maps unfamiliar domain concepts onto general
programming intuitions will make plausible-but-wrong decisions. The
definition does not need to be exhaustive — it needs to cover the concepts
most likely to be misunderstood.

**Non-obvious architectural decisions carry their rationale.**
When the structure of the system reflects a deliberate tradeoff — a chosen
pattern, a rejected alternative, a constraint from context — the reason is
recorded where a developer will find it. A decision without a recorded reason
will be revisited and potentially undone by every developer who encounters it.

**A path for making and submitting a contribution is documented.**
CONTRIBUTING.md or equivalent explains how to develop, test, and submit a
change. A developer knows what is expected before their first PR, not after.

**Known failure modes are documented.**
When the system breaks in known ways — a dependency that goes down, an edge
case that requires manual intervention, a recoverable error state — the
procedure is written down. Tribal knowledge that lives only in experienced
contributors' heads is a single-point-of-failure.

## Consider

**An architecture narrative exists.**
Beyond describing what files exist, a document explains how the system
thinks: how data flows, where decisions are made, why the boundaries are
where they are. A developer who understands the architecture makes better
decisions in novel situations.

**A recommended reading order exists.**
A new developer knows what to read first to build an accurate mental model
fastest. Without guidance, developers read whatever they find first, which
may be the wrong starting point.

**Significant decisions are logged.**
A decision log, ADR directory, or equivalent captures the history of
non-obvious choices and their context. A developer can understand how the
project evolved and what has already been considered and rejected.

## In scope

- README.md at the repo root
- CONTRIBUTING.md or equivalent
- Files under docs/, adr/, or equivalent documentation directories
- Inline comments that carry rationale for non-obvious decisions

## Out of scope

- User-facing documentation describing how to use the system (covered by ux)
- Agent-specific context files such as CLAUDE.md and settings (covered by agent-harness)
- Whether individual changed behaviours are documented (covered by documentation)
