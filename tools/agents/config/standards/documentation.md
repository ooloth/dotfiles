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

**Recorded facts name their source.**
A figure, limit, quota, or quoted behavior carries where it came from — vendor
documentation, a specification, a measurement. Numbers whose origin is an
untraceable conversation or a model's recollection are marked unverified or
left out. Once an unsourced figure sits in a document of facts it is
indistinguishable from a measured one, and decisions get built on it.

**Structured content reads as prose or lists rather than tables.**
Docs are read and edited as plain text far more often than rendered, and a
markdown table there is alignment padding nobody maintains: editing one cell
means re-padding its row, a formatter re-pads the whole block, and a one-word
change surfaces as a rewrite of every line. Grep reads paragraphs and lists
and mangles table rows. The exception is a lookup whose every row fits inside
the wrap width — an index, a key map — where scanning down a column is the point.

## Should

**New behavior appears in the right doc surfaces.**
A new flag appears in help text. A new config key appears in the example
config. Docs are updated in the same change that introduces the behavior.

**Examples are correct and runnable.**
Code samples in documentation execute without modification. Copy-paste
examples that silently fail are worse than no examples.

**Statements are unhedged, and what is uncertain is recorded as an open question.**
Caveats woven through prose — no evidence for this, unverified assumption, not
measurable yet — weaken every sentence around them while making none of it
actionable. The same content, stated as an open question somewhere a reader
looks for open questions, becomes work someone can pick up.

**Comments and documents describe the present (not the past or future).**
What a value used to be, what a rule replaced, which record was removed, how
far along the work is, when the content expires — none of it is visible to a
reader of the current state. Version control holds the past; whatever tracks
work holds the schedule. History earns its place only where it is the reason
the present is shaped this way — the regression a guard exists for, the
measurement that fixed a constant, the option that was tried and failed — and
it reads as a present fact rather than as a change narrative.

**Content that could be executed is executed.**
A rule that could be a type, a lint rule, or a test is that instead, and the
documentation points at it. Prose describing a constraint the toolchain could
enforce drifts from the code; the enforcement doesn't.

**An index entry describes what its target contains rather than restating its name.**
"errors — error handling" tells a reader nothing the filename didn't. An entry
earns its place by carrying what the name can't.

**References point to files rather than to headings within them.**
A path survives a document being reorganised. An anchor breaks silently the
moment someone rewords a heading, and nothing reports it.

**Prose wraps at 100 columns.**
Fixed-width wrapping keeps a diff to the lines that actually changed instead of
reflowing a paragraph because one word was added. Code blocks, URLs, and tables
wrap where they wrap.

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
