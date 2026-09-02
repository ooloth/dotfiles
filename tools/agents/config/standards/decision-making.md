# Decision Making

A technical decision is well made when its answer was reasoned from first principles and supported
by evidence, ideally first hand evidence, and when a reader who disagrees with it can see what would
change it.

## Must

**The order decisions are taken in is the order they depend on each other.**
Speed and familiarity do not move a decision earlier. How much a decision unblocks is different:
among decisions that do not derive from one another, the one unblocking the most is taken first,
because reaching the decisions that need making is the point of having an order. What is forbidden
is moving a decision ahead of something it derives from, whatever it would unblock. An out-of-order
answer is not wrong-looking — it is arbitrary and reads as considered, which is what makes the cost
fall on whoever inherits it.

**Every step between a decision and the problem it serves is named.**
A tool, a library, a runtime, a storage mechanism — each is the last step in a chain, never the
first. Find the chain by starting at the choice in front of you and asking what it rests on, then
asking the same of each answer, until every branch ends in something written down. Working the chain
out afterwards does not do the same job: one reconstructed after choosing contains only the steps
its author already believed in, which is why it always looks complete.

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

**A prerequisite found while deciding is settled before the decision that surfaced it.**
Not noted and carried past. Not answered provisionally with a plan to revisit. The prerequisite
is usually the less interesting of the two, which is exactly why writing it down and continuing
feels like progress.

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

**A spike is budgeted in hours, scoped to one observation, and deleted afterwards.**
The observation is the artifact. A spike kept around becomes a codebase nobody decided to have.

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
