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

**Comments and documents describe the present, never the past.**
What a value used to be, what a rule replaced, which record was removed, what
an earlier pass got wrong, how far along the work is, when the content expires —
none of it is visible to a reader of the current state, and all of it competes
with the instruction for their attention. Version control holds the past;
whatever tracks work holds the schedule.

Sentences containing _used to_, _previously_, _no longer_, _has since_, _so
far_, _originally_, or whose subject is a past session, author or incident are
rewritten without them, and the rewrite is what ships.

**A rule is stated without the incident that produced it.**
The war story is the most tempting form of this, because it reads as evidence
the rule is well founded. It is not: it adds nothing a reader can act on, and
it dates the rule to a situation that will not recur in the same shape. The
mechanism that makes the rule matter is what carries the weight, so that is
what is written. "A refusal here is the signal, not an obstacle" survives; an
account of the day somebody routed around it does not.

**A date attached to a source is provenance and stays; a date attached to our
own activity is narration and goes.**
"Read 2026-09-12" tells a reader how current a fact is and is load bearing on
whether to trust it. "Corrected on 2026-09-12" tells them about a session they
were not in. The two look alike and only one survives.

**History survives only as a forward-facing instruction.**
Where a reader lacking context would do the wrong thing — delete the guard,
change the constant, re-add the dependency — what ships is the instruction not
to, and the constraint that makes it so. Not the account of what went wrong
when someone did.

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

**Prose is followed in one pass, forward, without backtracking.**
A reader who reaches the third paragraph and has to return to the first has been
failed, however short the piece is. Length is not the measure. Draft it as you
would say it aloud, then write that: speech keeps one idea per sentence in the
order the reader needs them, joined by the words that carry the logic. Those
joining words and the distinctions an argument turns on are structure, not
padding — cutting them leaves assertions the reader has to reassemble.

**Statements are unhedged, and what is uncertain is recorded as an open question.**
Caveats woven through prose — no evidence for this, unverified assumption, not
measurable yet — weaken every sentence around them while making none of it
actionable. The same content, stated as an open question somewhere a reader
looks for open questions, becomes work someone can pick up.

**An invariant a machine could check is checked by a machine, not asserted in prose.**
Documentation and agent instructions are where unchecked invariants collect, so they are where to
look. An assertion that something matters in a docs without a corresponding check that
automatically monitors is just a nudge that can drift from reality. An instruction aimed at agents
or maintainers — remember X, never Y — is a check with no runner with no confirmation it's being
followed. Both read as settled and neither is. Either give it a runner or say why it cannot have one.

How it runs is a separate choice: a type, a lint rule, a test, a automated agent skill, an automated
script. Pick the most reliable, deterministic option available per case. Pair multiple methods when
that would catch what one method alone would miss.

Docs and non-deterministic inference are great ways to discover invariants that should be checked.
It's ok if a deterministic check starts its life as a wish in a code comment. Just graduate whatever
can be automatically checked whenever you can. When relying in part on non-deterministic checks,
try to extract any parts that can be made mechanical even where some judgement must remain.

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
