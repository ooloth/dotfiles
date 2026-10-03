# Decision Making

A technical decision is well made when its answer was reasoned from first principles and supported
by evidence, ideally first hand evidence, and when a reader who disagrees with it can see what would
change it.

## Must

**The order decisions are taken in is the order they depend on each other.**
Speed and familiarity do not move a decision earlier. What is forbidden is moving a decision ahead
of something it derives from, whatever it would unblock. An out-of-order answer is not
wrong-looking — it is arbitrary and reads as considered, which is what makes the cost fall on
whoever inherits it.

**Among decisions that do not derive from one another, the one whose wrong answer is cheapest to
unwind is taken first.**
Two things follow from taking it. Being wrong is survivable, so it can be taken before evidence
that only a later decision would produce. And making it produces evidence — a scaffold that runs,
an observation, a thing that exists — which every later decision is then made with rather than
without. Cheapness decides when a decision is taken, not how carefully it is derived: a
cheap-to-unwind decision still gets its properties derived and scored like any other. This is the same principle as deferring, read from the other end: the expensive decision
is the one that most needs what has not been learned yet, so it is the one that waits. Cheapest to
unwind counts discovery. A wrong answer nobody notices is not cheap however small the
fix would have been, so a decision that fails silently moves earlier rather than later, where the
thing it affects is still small enough to inspect. How much a decision unblocks is a reasonable proxy
and usually gives the same answer, because the
thing everything waits on is often the cheap one. It is not the criterion, because it is a property
of how the work was planned rather than of the system: redraw the milestones and the unblocking
counts change, while the cost of being wrong does not. Where the two disagree, the cost of being
wrong decides. Neither of these catches a decision that two open questions each defer to the other.
That is the Must below, and it runs first, because a tiebreak applied to decisions whose dependency nobody
noticed will order them confidently and wrongly.

**Every step between a decision and the problem it serves is named.**
A tool, a library, a runtime, a storage mechanism — each is the last step in a chain, never the
first. Find the chain by starting at the choice in front of you and asking what it rests on, then
asking the same of each answer, until every branch ends in something written down. Working the chain
out afterwards does not do the same job: one reconstructed after choosing contains only the steps
its author already believed in, which is why it always looks complete.

**The properties a decision is scored against are derived from what the system does, not inherited
from what has already been written about it.**
A criteria list assembled from the documents in front of you is the previous author's list, and it
reads as complete precisely because it was written as a summary. Derive it from what the thing being
chosen will actually do, by listing the concrete moments the system touches it: each request,
write, read, deploy, failure and wait it takes part in. "The network" returns nothing to reason
about, and "a returning user's first request after the page has loaded" returns a property a
candidate either has or lacks. Each property cites what it rests on, and one that can cite nothing
rests on an input that is not settled yet. Then compare: where the inherited list is a subset, the
difference is what would otherwise have been decided without. The same test settles whether the question is even
well-posed, because a question none of the derived criteria can discriminate on is the wrong
question however reasonable it sounds. "One tool or several?" is unanswerable when nothing the
system requires is about how many tools there are, and a question like that will absorb a survey
and return a preference wearing a derivation.

**The derived properties are written down before any option is named.**
Deriving them and keeping them in your head satisfies nothing a reader can check. A recommendation
presented without the list reads as reasoned whether or not the reasoning happened, and a property
that was never derived is invisible in exactly the way a derived one is. The list is also the only
part of the record a reader can disagree with before the conclusion has framed the question for
them.

**Implementation effort is a constraint, never a merit.**
A stated budget rules an option out. Nothing rules one in on effort. "Simpler to build", "a smaller
diff", "less to configure" and "fewer moving parts" each name what an option costs, and none of
them names anything the system requires, so an option that wins on one of them has not been
compared on anything. The tell is a comparison whose merit column contains a cost. Where effort seems
to be the only thing separating the candidates, the property list is not finished: it is extended
and zoomed, per the entry on comparisons that leave several candidates standing. A cost the
maintainer has stated a view on, such as a budget or a strong wish for something to be free, enters
that list as a cited row rather than deciding from outside it.

**A predicted failure mode is a constraint on the design, never a reason to drop the requirement.**
"It would degrade into busywork" and "it would be ignored" describe how a bad version of the thing
fails. Neither says the thing is not needed. The prediction narrows which designs are acceptable,
so the work is to find one that survives it, and the tell that this went wrong is a recommendation
justified by the good version being hard to specify. Where no design survives the constraint, that
is the finding and it is recorded as one, rather than arriving as a preference for leaving the
requirement out.

**Every architectural decision considers CPU, memory, storage and network, and records which of them
do not bind and why.**
These four are what software eventually runs on, so they generate candidate criteria reliably where
a topic-driven list does not. Each is asked along three axes: how much is consumed, how fast it
moves, and how long one operation takes. Ask them by enumerating the moments the system touches that
resource rather than in the abstract, because "storage" returns nothing and "the request path reads
a row, a write is flushed, a backup is copied off the machine, a migration rewrites a table" returns
a list you can reason about. These moments are the same ones the property list is derived from,
applied to the four resources. Most will not bind, and saying so is the point: "memory does not bind,
because the workload is X and the smallest instance is Y" and silence about memory are
indistinguishable in a finished record, and only one of them was considered. This is not a mandate
to measure. A property recorded as not binding needs a reason rather than a number, and the Must
against measuring what does not bind still applies.

**Every property belongs to one of three categories, safety, performance or experience, and before
a tradeoff between them is accepted, the theoretical maximum of each is stated and a design reaching
all three is looked for.**

- **Safety** is every way the system can go wrong or cause harm, and whether it notices. It
  includes correctness, reliability, security, data integrity, bounded resources, and checking
  itself while running so that it stops rather than carrying on wrong. That list is where to start,
  not where to stop. Maximum safety is a system that cannot go wrong or cause harm without noticing.
- **Performance** is how little anyone waits, on the path they wait on, and how little of the
  machine's resources (time, memory, battery, network) the work spends. It is judged at the slowest
  cases as well as the typical one. Fewest steps is not the same thing: parallel work, work done
  ahead of time and batching all add steps and can cut the wait. Maximum performance is the physical
  floor: the round trips the work cannot avoid on the network it runs on, plus the computation it
  cannot skip on the hardware it runs on.
- **Experience** is what users and developers live with: how clear, direct and easy to change the
  thing is. Maximum experience is the least a user or developer has to know or do to get what they
  came for.

Before any maximum is stated, the ways a bad design could fail are listed in all three categories:
how it could go wrong or cause harm, how it could be slow, and how it could be hard to use or to
change. The list
is written before any candidate or check is named, and the maximums and properties are derived from
it. The question's topic is what narrows attention. A question about storage pulls it to lost data,
and away from a process that dies without anyone knowing, an input nobody checks, or a deploy nobody
can undo. Writing the failures out first, category by category, is what widens it again.

The three are not ranked, and none is traded for another by default. A tradeoff between them often
means the design is not finished, because a different design can remove it. A tradeoff that
survives the search names the physical fact that forces it, and is then argued from the properties.

The tell that this step was skipped is options presented as points on one curve, such as "fast or
correct", "fast or validated" or "simple or safe", with no option asking whether the curve can be
left.

**A benefit is weighed net of what the system already owes by other means.**
An option that buys something the system will have anyway has bought nothing. The benefit counts
only as the difference from what is already required. The tell is a benefit column listing
something another record already mandates.

**Decisions are sequenced so that a milestone is reached in a state worth keeping.**
Dependency order is the mechanism; reaching a milestone in a state you would keep is the goal. If
you would expect to redo a choice shortly after the milestone, it is missing an input or the
milestone is drawn in the wrong place. Provisional is not a category: either the choice waits, or
what it waits on joins the milestone.

**A decision's inputs are settled before it is taken.**
Every input is a fact somebody established, a promise already made, a stated goal, or an
earlier decision. An input that is an inference is an undecided question, and it is decided
first. This is the failure that does not announce itself: a derivation from an unchosen premise
stays invisible precisely because the reasoning built on top of it is sound, so it reads as
reasoned for months and is found by accident.

**Each input names the record that established it.**
Not "this is consistent with what we have written" — _which record settled this, and where is it._
The two questions feel alike and catch different things: consistency is satisfied by any claim
nothing contradicts, which is exactly what an unrecorded assumption looks like from the inside.
Where no record can be named, the input is an open question and it is asked rather than assumed,
however obvious the answer seems and however many documents already repeat it.

**A prerequisite found while deciding is settled before the decision that surfaced it.**
Not noted and carried past. Not answered provisionally with a plan to revisit. The prerequisite
is usually the less interesting of the two, which is exactly why writing it down and continuing
feels like progress.

**A choice that two or more open questions each defer to the other is an open question in its own
right.**
It is invisible to a reader of any single one of them, because each reads as having handled it by
pointing elsewhere. And it is settled by whichever of the deferring questions is answered first,
which lets the narrowest choice in the set decide the widest — the same failure as taking a decision
out of order, arrived at without anyone taking a decision at all. The deferral is the tell: where a
file says the answer depends on another file that says the same back, nobody owns the thing in the
middle. This is not the same as a prerequisite found while deciding, which is found because somebody
was deciding; this one survives precisely because nobody is.

**Research precedes measurement, and neither substitutes for the other.**
Reading first is what tells you which properties are worth observing — including the ones you
would not have thought to look for, which are the ones a spike designed in ignorance silently
omits. Reading does not reach the answer. A number found in someone else's benchmark is a
hypothesis about what will be observed here, and it is treated as one until it has been.

**A measurement carries its method.**
What was run, on what hardware, how many times, against what baseline. A figure without its
method is an assertion with a number in it, and it reads as stronger than a sourced claim while
being weaker.

**A measurement measures the thing the decision turns on.**
A benchmark that does not resemble the real workload is worse than no number, because it carries
the authority of evidence without the substance. Four ways this goes wrong: measuring a quantity
that does not bind, measuring in an environment where the failure cannot occur, measuring a
synthetic workload that does not resemble the real one, and measuring once so that variance —
often the actual finding — stays hidden.

**Rejected options are ones a competent person would have chosen.**
Not plausible alternatives assembled to fill a section. Where no such option exists, there was no
decision — there was a description of the problem. A template with a "rejected" heading will
accept invented alternatives, and the format then lends authority the reasoning never earned.

**Each option is argued before one is chosen.**
Write the case against each option, and the case for it, before picking. An option you can only
argue against after choosing a winner was not evaluated — it was justified against, which is a
different thing that produces the same-looking text. The tell that this went wrong is that the weak
reasoning all points one way: nobody writes a flimsy argument for the option they took.

**Every option is evaluated from first principles, on evidence.**
No claim carried over from an earlier document without re-establishing it. No assumption stated as
a fact. No number without its method, and no specific-sounding detail that nobody checked — those
are the most convincing thing in a bad argument, because they read as research. Where a reason
cannot be sourced, the record says the reason is unverified rather than dropping the qualifier and
keeping the confidence.

**A rejection cites its evidence, exactly as the decision does.**
The reasoning that forecloses an option is held to the same bar as the reasoning that chose one. It
is the half more likely to go unchecked, because a chosen option gets tested by reality and a
rejected one never does — its stated reason is the last word on it, permanently.

**One reason disqualifies an option, and it is named.**
Not a stack of three. Three individually weak reasons read as one strong case, and nobody asks
which is load-bearing. If none of them would disqualify the option alone, the option is not
disqualified yet.

**A rejection says what would have to change to reverse it.**
Otherwise it is permanent by default and nobody can tell whether it still holds. This is the same
service **revisit when** does for the decision, applied to the roads not taken.

**One record settles one decision.**
The test is whether a reasonable person could have decided the headline one way and the second
thing the other way. If they could, that is two decisions, and bundling them means one of them
never gets argued — it rides along on the other's reasoning and inherits authority it was never
given. Unpack a bundle into a chain instead, each link resting on the one before and carrying its
own rationale. The chain is longer and every step is checkable.

**A decision that follows necessarily from an earlier one is still recorded.**
It constrains implementation the same way a chosen one does, and a constraint that lives only
inside another record's reasoning is invisible to anyone scanning the list. Its "rejected" section
says plainly that reversing it means reversing the parent, rather than inventing an alternative.

**A decision the next milestone does not need is not made.**
The test is not whether the question could be answered — most could, badly. It is whether reaching
the next observable state requires the answer. Deciding early costs twice: everything learned
between now and when it was needed is information the decision was made without, and once a record
exists everything after it treats the choice as settled, so a premature decision is
indistinguishable from a load-bearing one.

Deferring is not deciding provisionally. A deferred question stays open with nothing built on it.
If a milestone appears to need a provisional answer, the milestone is drawn in the wrong place.

**A claim's provenance is recorded alongside it, including when there is none.**
Measured, sourced, reasoned, or unverified. The last is the most useful of the four, because an
unsourced number reads exactly like a sourced one and nothing else distinguishes them. Claims
inherited from earlier documents are unverified until somebody re-establishes them.

## Should

**A decision whose inputs can be observed is observed rather than argued.**
Where the smallest throwaway thing that produces an observation would settle a question, that is
what settles it, and the record cites the observation. This holds most strongly for tool, runtime
and library choices, where published numbers describe someone else's workload on someone else's
hardware. The exception is where the spike would cost more than being wrong — that is stated
rather than assumed.

**Research settles what a document can settle, and running settles what only running can.**
A property a candidate documents having or lacking is established by reading, in an hour, and a
negative result costs nothing. A property that only holds or fails in practice is established by
running. Neither is the default, and the two failures are symmetrical: running a comparison a
document would have settled, and asserting from a document what only running can show. The entry
above pushes toward observing and is silent on the first of those, which is the more expensive
mistake on a question whose candidates publish what they can and cannot do — most of a tool or
runtime field is eliminated by reading, and the spike is then aimed at whatever survives.

**The moments a choice is scored on include the years of maintaining it, not only the day it is
adopted.**
A choice is lived with long after it is made. It is set up, configured, patched, upgraded across
versions that change its behaviour, debugged when it surprises someone, rebuilt when its machine is
lost, and kept while the project behind it changes hands. Each of those is a moment the system
touches the choice, and each yields properties as concrete as the request path's: how much there is
to configure and keep in mind, what an update does to the running system, how a failure makes
itself known, how easily help is found, and what replacing the choice would cost. A property list
derived only from adoption favours whatever is quickest to stand up, and says nothing about what the
maintainer pays every month afterwards. The horizon is the system's expected life, as its problem
statement or its maintainers set it. A throwaway prototype has a short one, and says so.

**A measured property is weighed beside the rest of the list, not in place of it.**
A measurement is the strongest evidence a comparison holds, for the one property it measures. A
candidate that loses a measured row has lost that row, read in light of what the difference costs
over the system's life. It is disqualified only where the row is a requirement it fails outright,
which is the Must that one named reason disqualifies an option. The tell is a comparison settled by
the one column that happened to be measurable, while properties the maintainer weighs more stay
unread.

**Research is assigned by property, not by candidate.**
A researcher given a candidate returns a survey of that candidate, and the comparison is then
assembled from several surveys that each chose their own axes. A researcher given a property
returns a verdict for every candidate on the axis the decision turns on, with its source, and that
verdict goes straight into the comparison. Enumerating the field is its own assignment, so the
candidates are not limited to the ones already named, and a property a researcher finds that the
list missed joins the list before any option is compared.

**The comparison shows every option against every derived property, and each rejection names the
property it fails.**
A comparison written as prose per option lets each option be judged on whichever properties flatter
or sink it. A grid shows where an option was never assessed, makes the one disqualifying property
visible, and shows when two options differ on nothing the list contains. That is the signal to
extend and zoom the list, per the entry below. A grid in the working is enough; the record carries the
properties and names the one each rejection fails.

**A check earns its place when it can name the property, the requirement that binds it, and which
candidates leave the field on each outcome.**
A check that eliminates nobody is not wasted when it was cheap and its outcome was genuinely open —
a negative result is a finding, and it stops the work that would otherwise have been spent on the
property it cleared. It is wasted when the outcome was known before it ran, which is the shape a
check takes when it is really a demonstration.

**A spike is budgeted in hours, scoped to one observation, and deleted afterwards.**
The observation is the artifact. A spike kept around becomes a codebase nobody decided to have.

**A spike built on one candidate confirms; it does not choose.**
It can show whether a property is reachable at all, and a failure there is worth knowing. It cannot
show that what was built beats what was not, so the choice of which candidate to build becomes the
decision, made by whichever was nearest to hand. One candidate is built only where the field is
already down to one on other grounds, and then the spike confirms it against a named falsifier.
Where two or more remain, the spike covers them all and measures only the property that separates
them, not the whole system under each.

**A survey states what it did not examine.**
A question answered as "can each candidate do X" has not asked how well, at what cost, or with what
failure mode, and that gap is invisible in the answer. Naming the unexamined axes costs a sentence
and lets a reader judge whether the omission was reasonable rather than discovering it later as a
surprise.

**A comparison that leaves more than one candidate standing is extended and zoomed before anything
is chosen.**
A first pass through the properties rarely finishes a decision, and several survivors mean the list
is not finished yet. It does not mean the candidates are equal. Two moves continue it.

- **Zoom in.** Each property that every survivor passes is shorthand for several conditions, and one
  of those may separate them. "Fast enough" can stand for the median, the slowest percentile, the
  first request after idle and the oldest supported device, and candidates that tie on one often
  differ on another.
- **Extend.** Derive properties from moments not yet listed. Softer ones belong here too once the
  technical ones stop separating: what employers look for, what a maintainer will live with for
  years, what AI assistants have learned from. Each enters as a row citing its source, such as a
  stated goal or a stated preference, never as a tie-breaker outside the table.

Then score again, and write each pass down with its date. The decision is what the table yields, and
it is presented as derived from the table.

This keeps the protection the Must that one reason disqualifies an option exists for: three weak
reasons must not read as one strong case. Every row cites its source, so a weak reason is visibly a
weak row rather than a stack of prose. Where a pass changes no verdict, the next pass zooms into a
different property or extends to a moment not yet covered. Stopping on "no property separates them"
is a finding only after both moves have been tried and recorded. The tell that this was skipped is a
record whose decision rests on a preference that appears nowhere in its property list.

**An unknown is not a pass.**
A candidate whose verdict on a property is unknown is neither kept nor dropped on that property. The
unknown is resolved first, or it is stated as the reason the comparison cannot finish yet. A grid
that carries unknown cells into a recommendation has decided those cells without evidence, in
whichever direction the recommendation needed.

**A decision names what else it moves before it is recorded.**
Decide one thing at a time, and look at the whole system while doing it. Two failures pull in
opposite directions: bundling several decisions into one record so that none of them is argued,
and settling one narrowly while foreclosing others by consequence. Naming the second is what
stops a choice being made without anyone noticing it was made.

**Options are weighed by what each forecloses, not by which is better today.**
Present merit is the weakest of the available criteria and the one every comparison reaches for
first, because it is the easiest to feel and the hardest to check. Options are usually close on it,
and the apparent gap is mostly familiarity. What separates them is what each makes expensive to
reach afterwards: run every candidate forward and ask which futures it keeps in play, which it
closes, and what reopening each closed one would cost.

The asymmetry that falls out is usually the decision. It is also the step where a preference gets
laundered into a derivation, so the asymmetry is traced rather than asserted — name the specific
later work each direction would require, and check that the cheap direction is actually cheap
rather than merely the one already preferred. An asymmetry that cannot be stated as concrete work
is not evidence of anything.

Product optionality is the form this usually takes, and it outranks developer convenience where
the two disagree. A choice that saves effort now and removes a thing the product could have become
has to say so plainly, because the effort is visible on the day and the removed future never
announces itself.

**A decision that closes an option says so, and says what it would cost to reopen.**
Most choices that feel urgent are reversible in an afternoon. The ones worth stopping for are the
ones that quietly make something later expensive — a hosting layout that caps a recovery mechanism,
a data shape that assumes one kind of record, a missing identifier that turns a later feature into
a migration. In each case the option is kept open by a small decision taken early and closed by an
equally small decision taken without noticing. Neither costs much. Only one is recoverable.

So before recording a choice, ask what it makes harder later, and say so in the record. An option
worth keeping open is named in the record that keeps it open, not in a register somewhere else — a
separate list of things to protect is a second copy that goes stale, and the reader who needs it is
reading the decisions.

Keeping an option open is not free either. Each one constrains every decision after it, and an
option nobody ever takes was a cost paid for nothing. Say what the option is for, and drop it once
that use is genuinely abandoned.

**A decision record names the observable condition that would reopen it.**
A condition, not a date. Without one, every record reads as equally binding forever, and a future
reader cannot tell whether circumstances have crossed the line.

**Familiarity is stated as a cost of the alternative, never as a merit of the choice.**
"I already know X" is a legitimate input. Smuggled in as a property of X, it is an argument that
cannot be checked.

## Consider

**A decision found to rest on something unsettled is demoted rather than annotated.**
A caveat added to a record leaves it among the settled things, where the next reader cites the
conclusion and misses the qualification. Moving it back to an open question keeps the reasoning
and removes only the standing.

**Three options, one of which is "not yet".**
Two options is a coin toss with extra steps. Doing nothing, or the dumbest thing that would work,
is the most frequently correct and least frequently considered option.

**Each option's failure mode is predicted before choosing.**
An option that fails silently loses to one that fails loudly, even when it is otherwise better.

## In scope

- Architecture decision records and any equivalent written record of a choice
- Any choice of tool, library, runtime, platform, or data shape, whether or not it gets a record
- Spikes, prototypes and benchmarks run to settle a choice

## Out of scope

- Which decision is taken next, and in what order — that depends on what the project is reaching
  for and belongs in the project's own standards
- Choices inside an already-decided area: naming, file layout, formatting
- Reversible experiments that nothing else depends on yet
