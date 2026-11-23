# Documentation

Documentation is part of the system it describes and is held to the same three properties as the
rest of it, as `decision-making.md` defines them. At its maximum:

- **Safety:** a reader who does what a doc says gets the result the doc says, with no effect the
  doc does not name, and a doc that has stopped being true is caught before anyone acts on it.
- **Performance:** a reader reaches the part they need from where they start in the fewest hops
  and reads it once, forward. The reader acting under time pressure, such as during an incident,
  sets the bar.
- **Experience:** a doc holds only what its reader cannot get from the source of truth, in a form
  they can act on without filling anything in, and is absent where the code speaks for itself.

## Must

**Docs reflect current behavior.**
A doc says only what is true of the system it describes, whether it is new or already in the repo.
When behavior changes, the docs that describe it change too. After a merge, no doc still describes
behavior the merge changed, such as a removed flag or an outdated command signature. A doc that
describes something another repo or system owns is checked against that source whenever the doc is
reviewed, because a change there reaches the doc without a merge here.

**Public interfaces are documented.**
Every interface a caller uses, such as an API or a CLI command, has documentation
describing what it does, what it accepts, and what it returns. A caller
can use it without reading the implementation.

**Non-obvious code has a comment explaining why.**
Anything in the code that would surprise a reader, such as a hidden constraint or a workaround for
a specific bug, has a comment. What the code does is
not explained — well-named identifiers do that.

**A doc or comment holds only what its source of truth cannot say.**
What only a person can say, such as a reason, a rejected option or a trap, belongs in prose. A
fact its source already states, such as code or a canonical external page, is
linked, not copied, because a copy goes stale at the next change to its source. An identifier a
command needs in order to run is part of the command, not a copy. A value quoted to show how a
figure was worked out links its source.

**Recorded facts name their source.**
Every fact a doc records, such as a figure or a quoted behavior, carries where it came from, such
as the page, file or measurement it was read from. That includes a comment in code or
config that states what a third-party tool does with a setting: the comment cites the doc page or
source file that says so, and the claim was checked there, not recalled. Where the docs are silent,
the tool's source decides.
Numbers and behaviors whose origin is an untraceable conversation or a model's recollection are
left out. Once an unsourced figure sits in a document of facts it is indistinguishable from a
measured one, and decisions get built on it.

**A recorded absence rests on two sources that agree, or says why only one exists.**
A claim that something is absent, such as "no errors in the logs", is a fact
like any other, and one empty result supports it less than it seems to. Many
failures return the same empty answer as a true absence, such as a filter the source silently
ignored or a query aimed at the wrong place. So an absence is recorded only
when an independent second source agrees, or with the reason only one source
exists. Where two sources disagree, both are recorded and the disagreement is
the finding.

**Comments and documents describe the present.**
Anything about the past or the schedule, such as what a value used to be or how far along the work
is, is invisible to a reader of the current state, and all of it competes
with the instruction for their attention. Version control holds the past;
whatever tracks work holds the schedule.

Sentences that narrate change over time, with words such as _used to_, _previously_ or _no
longer_, or whose subject is a past session, author or incident, are rewritten without it, and the
rewrite is what ships.

A document holds no list of steps the team still has to take, and no qualifier
such as _being removed_, _once X lands_ or _until TICKET ships_. Each step still
to take is a ticket, and the document says what is true now. A procedure a
reader repeats, such as rebuilding an environment, is not work in progress and
stays.

**A rule is stated without the incident that produced it.**
The war story is the most tempting form of this, because it reads as evidence
the rule is well founded. It is not: it adds nothing a reader can act on, and
it dates the rule to a situation that will not recur in the same shape. The
mechanism that makes the rule matter is what carries the weight, so that is
what is written. "A refusal here is the signal, not an obstacle" survives; an
account of the day somebody routed around it does not.

**A date that says when a source was read stays, and a date that says when work happened goes.**
"Read 2026-09-12" tells a reader how current a fact is and is load bearing on
whether to trust it. "Corrected on 2026-09-12" tells them about a session they
were not in. The two look alike and only one survives. A measurement's date is the first kind: it
says when the figure was read.

**History survives only as a forward-facing instruction.**
Where a reader lacking context would do the wrong thing, such as deleting a guard, what ships is the
instruction not to, and the constraint that makes it so. Not the account of what went wrong when
someone did.

**Every command or procedure a doc says works has been shown to do what the doc says.**
Running without an error is not the bar. A command can succeed and then be undone by something else
that owns the same state, such as a controller that reconciles to a declared spec, or it can change
more than the doc says. Before a doc that gives one is committed, its commands are run against the
system they target. Where running would change production, they run in a mode that checks every
name and reference against that system without writing to it, such as a server-side dry run rather
than one that checks only locally, and whatever that mode cannot show,
such as another owner putting the old state back, is read from the configuration that decides it.
Where no such mode exists, the configuration that decides the outcome is read instead. The change
that adds or edits the doc records what was run and what it showed, so a reviewer checks the run
instead of asking for it. A review of a doc already in the repo checks its commands the same way an
author would, instead of looking for that record.
Every effect beyond the step's stated purpose, and every other owner of the state it changes, is
named in the doc.

**Structured content reads as prose or lists rather than tables.**
Docs are often read and edited as plain text rather than rendered, and a
markdown table there is alignment padding nobody maintains: editing one cell
means re-padding its row, a formatter re-pads the whole block, and a one-word
change surfaces as a rewrite of every line. A line search reads paragraphs and
lists and mangles table rows. The exceptions are a lookup whose every row fits inside
the wrap width, such as an index or a key map, where scanning down a column is the point,
and output read rendered and not edited afterwards, such as a ticket comment or
PR description.

## Should

**Behavior appears in the right doc surfaces.**
Each behavior appears on every surface where a reader looks for it, such as a flag in help text or
a config key in the example config. Each surface gets its entry in the same change as the behavior
it describes, so none is left without one. A surface that has gone stale falls under the Must that
docs reflect current behavior. This claim covers one that never got its entry.

**A decision reaches every reader it binds, each in the place that reader looks.**
The reasoning and the rejected options sit in one decision record, except for a
decision taken on the spot under the decision-making standard's triage, whose
commit message is its record. What the
decision commits the project to sits wherever that commitment is checked, such as the standards
for a rule reviewers apply. Each of those entries links to the record rather than restating its
reasoning. A decision recorded only as a record binds only the people who
think to open it, and one restated in full in several places drifts into
versions that disagree.

**A procedure that changes data gives the statement to run.**
A step that asks the reader to update or delete rows names the exact
statement, the count it should report, and a guard count that uses the same
predicate as the write. A mismatch then stops the reader before it changes a
row they did not mean to change. A step that leaves the statement to the
reader has them improvise a write against production.

**A step that changes a production system says how to tell it worked and how to undo it.**
The reader is told what to look at and what it shows once the step has taken effect, and which
step reverses it.

**A procedure run against production states how long it takes and what serves while it runs.**
A reader choosing between procedures under time pressure needs the time each takes on its slowest
path, and what users get meanwhile.

**A doc needed during an incident is one link from the repo's entry points.**
Whatever a reader needs while production is failing lives in the README or the agent context file,
or one link from them, so a reader who starts where everyone starts reaches it in one hop.

**A command a reader runs against a real system is complete as written.**
Every value the reader would otherwise look up is filled in, or the doc says exactly where to get
it. A placeholder with no source sends the reader to guess, and a guess aimed at the wrong target
runs without complaint. Illustrative values in examples that run against nothing are out of scope.

**A check a procedure asks the reader to run can be seen to fail.**
A step that has the reader compare an answer with an expected one is a test run by hand, and the
bar `testing.md` sets for a passing test applies to it: the condition the step guards against has
been made to happen, or traced through the code to the answer it would produce, and the step then
reports a failure. A step whose failure cannot occur reports a pass whatever the system does, and a
reader who trusts it stops looking where the fault is. One cause is a default that answers
every input the same way, such as a server that returns one page for every path it has no file for.

**Absolute claims hold for every case that could break them.**
A sentence that makes an absolute claim about a system, with a word such as only, every or never,
holds for every other case that could break it, such as another mode, a slow clock or an unusual
input. An absolute can be false with nothing in the text to show it, because the path that breaks it
is usually one the writer did not think of.

**Prose is followed in one pass, forward, without backtracking.**
A reader who reaches the third paragraph and has to return to the first has been
failed, however short the piece is. Length is not the measure. Prose reads the way it
would be said aloud. Speech keeps one idea per sentence, in the order the reader needs them, joined
by the words that carry the logic. Those
joining words and the distinctions an argument turns on are structure, not
padding — cutting them leaves assertions the reader has to reassemble.

**A list of examples says it is examples, and the general idea comes first.**
A reader takes an unmarked list as the whole set and stops looking past it. Stating the general
idea first, then a few cases introduced with a phrase such as "such as", tells them the list is a
start.

**A diagram shows what prose would have to describe one piece at a time.**
When understanding a change means holding several parts in mind at once, such
as actors exchanging messages, states and the transitions between them, or
components and what depends on what, a diagram shows them together where prose
makes the reader assemble them. The form follows the question the reader has. These are examples,
not a complete list:

- Who talks to whom, and in what order: a sequence diagram
- What states a thing can be in, and what moves it between them: a state diagram
- What the code decides, and which path each input takes: a flowchart
- What depends on what: a dependency graph
- What is stored, and how the pieces relate: an entity-relationship diagram
- What happens in what order during a rollout or migration: a timeline
- How a value changes shape from input to output: a data-flow diagram

Where the content is a set of
combinations, such as options scored against properties or inputs mapped to
outcomes, a table shows it better than a diagram, wherever the claim on tables allows one. Where
a change alters a structure, a before and after pair shows the change itself. A diagram is
included only when it replaces prose or shows something the prose does not. One
that restates the surrounding text, or that holds two boxes and an arrow, is
left out.

**Diagrams are plain text in a code block, no wider than 100 columns.**
They are read in terminals and in trackers that do not render diagram
languages, and plain text looks the same in all of them. A diagram language shows as source
wherever it is not rendered. At 100 columns or
less, a diagram does not wrap in a narrow terminal or comment pane.

**Statements are unhedged, and what is uncertain is recorded as an open question.**
Caveats woven through prose, such as "not verified yet", weaken every sentence around them while
making none of it actionable. The same content, stated as an open question somewhere a reader looks
for open questions, becomes work someone can pick up.

**An invariant a machine could check is checked by a machine, not asserted in prose.**
Documentation and agent instructions are where unchecked invariants collect. An assertion in a doc
with no check that monitors it is a nudge that drifts from reality, and an instruction to agents or
maintainers to always or never do something is a check with no runner and no sign it is followed.
Both read as settled and neither is. Each one either has a runner or states why it cannot have one.

How it runs is a separate choice: whichever mechanism is most reliable and deterministic for the
case, such as a type, a lint rule or a test. Several mechanisms are paired where together they
catch what one would miss.

Docs and non-deterministic inference are good places to discover invariants worth checking, and a
check can start as a wish in a code comment. Whatever can be checked automatically graduates to a
check, and where judgement must remain, the parts that can be made mechanical are extracted from it.

**An index entry describes what its target contains rather than restating its name.**
"errors — error handling" tells a reader nothing the filename didn't. An entry
earns its place by carrying what the name can't.

**References point to files rather than to headings within them.**
A path survives a document being reorganised. An anchor breaks silently the
moment someone rewords a heading, and nothing reports it.

**Docs and code comments state what to check, not a shell search to run.**
A pattern breaks silently when the text it matches changes.

**Prose wraps at 100 columns.**
Fixed-width wrapping keeps a diff to the lines that actually changed instead of
reflowing a paragraph because one word was added. Code blocks, URLs, and tables
wrap where they wrap. A file wrapped some other way keeps its own
convention until it is rewrapped in a commit of its own, so no diff mixes the two.

## Consider

**Changelogs are updated for user-facing changes.**
When the project maintains a changelog, additions, removals, and breaking
changes to user-facing behavior have an entry.


## In scope

- README.md at any level
- .md files under docs/, .claude/, or similar doc directories
- Module-level doc comments, such as a docstring at the top of a file
- Inline comments, for the standards that name comments, such as whether a comment explains a
  non-obvious why
- Ticket comments and PR descriptions, for the diagram and table standards

## Out of scope

- Illustrative paths, such as path/to/your/config.toml
- Commands in sections explicitly marked as planned or not yet implemented
- External URLs
