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
config. Docs are updated in the same change that introduces the behavior.

**Examples are correct and runnable.**
Code samples in documentation execute without modification. Copy-paste
examples that silently fail are worse than no examples.

**Comments describe the code as it is, not as it was.**
A comment narrating a previous implementation — what a value used to be, what
a rule replaced, which element a removed box enclosed — describes something no
reader of the current code can see, and costs clarity to carry. History earns
its place only where it is the reason the code is shaped this way: the
regression a guard exists for, the measurement that fixed a constant, the
option that was tried and failed. That reason reads as a present fact about
the code rather than as a change narrative.

## Consider

**Changelogs are updated for user-facing changes.**
When the project maintains a changelog, additions, removals, and breaking
changes to user-facing behavior have an entry.

**Diagrams reflect current architecture.**
Visual representations of system structure, data flow, or component
relationships are updated when the structure they depict changes.

## In scope

- README.md at any level
- .md files under docs/, .claude/, or similar doc directories
- Module-level doc comments (//! blocks, docstrings at file tops)
- Inline comments, for the two standards that name them: whether a comment
  explains a non-obvious why, and whether it describes the code as it is

## Out of scope

- Illustrative paths (path/to/your/config.toml, \<owner\>/\<repo\>)
- Commands in sections explicitly marked as planned or not yet implemented
- External URLs
