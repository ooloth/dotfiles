# Documentation

Documentation is correct when it accurately describes the current behavior,
complete when it covers what a reader needs to use or maintain the code
without asking the author, and absent where the code speaks for itself.

## Must

**Existing docs reflect current behavior.**
When behavior changes, the docs that describe it change too. Stale examples,
outdated command signatures, removed flags, and superseded architecture
descriptions don't exist after a merge.

**Public interfaces are documented.**
APIs, CLI commands, config keys, and exported types have documentation
describing what they do, what they accept, and what they return. A caller
can use them without reading the implementation.

**Non-obvious code has a comment explaining why.**
Hidden constraints, subtle invariants, workarounds for specific bugs, and
behavior that would surprise a reader are annotated. What the code does is
not explained — well-named identifiers do that.

## Should

**New behavior appears in the right doc surfaces.**
A new flag appears in help text. A new config key appears in the example
config. A new architectural decision has a record. Docs are updated in the
same change that introduces the behavior.

**Examples are correct and runnable.**
Code samples in documentation execute without modification. Copy-paste
examples that silently fail are worse than no examples.

## Consider

**Changelogs are updated for user-facing changes.**
When the project maintains a changelog, additions, removals, and breaking
changes to user-facing behavior have an entry.

**Diagrams reflect current architecture.**
Visual representations of system structure, data flow, or component
relationships are updated when the structure they depict changes.
