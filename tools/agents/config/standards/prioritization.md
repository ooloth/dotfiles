# Prioritization

A ranking of work is well made when the work it puts first is the work whose delay costs the most
for the effort it takes, and when a reader who disagrees can see why each item sits where it does.
It ranks work items: tickets, untracked steps toward a goal, and work in flight. Choosing between
options for one decision belongs to `decision-making.md`. At its maximum:

- **Safety:** nothing whose delay is causing serious harm now sits below work that only saves time,
  and no rank rests on a claim nobody checked.
- **Performance:** the reader learns the next action and its reason in one read of the ranking, and
  the investigation behind it goes deepest where a wrong rank would cost the most.
- **Experience:** the reader brings what they care about and nothing else. The ranking finds the
  work, including work nobody has tracked, and gives its reasons in plain words the reader can
  overrule.

## Must

**Each rank rests on a judgement of cost of delay against size, and the sentence that decided it
is shown.**
Cost of delay is what each day of waiting costs the people the work serves: the pain, slowness,
loss or harm they meet, and how often they meet it. Size is how much the item takes compared with
the other items, judged from what can be counted: the steps it needs, the systems it touches, the
people or teams who must act before it is done, and the unknowns to settle first. Waiting on people
is usually most of the calendar time work takes, so handoffs weigh more than the amount of change.
Size is never stated as hours, days or weeks, because that presents a guess as a measurement. The
rank is a judgement, not a score, because estimates of either are too rough to compute
with and a formula fails on the first list unlike the ones it was written for. The shown sentence is
what makes the judgement checkable: a reader who disagrees knows what to dispute. Size counts here
although `decision-making.md` holds that the effort to build an option is never a merit. There, the
options are competing ways to meet one set of requirements, and only one gets built. Here, every
item is meant to get done and only the order is in question: doing a small valuable one first
delivers its value sooner while delaying a large one only a little.

**Harm that is happening now outranks size.**
When delay causes serious harm that is already under way, such as breaching a contract, an open
security exposure, data being lost, or a cost that grows every day, the item ranks by that harm
however large it is. Size changes the order only between items whose costs of delay are comparable.
This is judged by consequence, not by category: a ticket labelled compliance may cost little to
leave, and a speedup on the path that bills customers may cost a great deal.

**A cost that jumps at a date ranks by the date and by what has to happen before it.**
A renewal, an audit or a release costs little to delay until its date and a great deal after. Such
an item names its date, and ranks higher the nearer the date is and the more steps and handoffs
stand between it and done. Whether the work still fits before the date is the reader's judgement,
since it turns on calendar time the ranking cannot see.

**Ticket metadata is evidence, not a verdict.**
Priority, severity, labels, estimates and status are often defaults, stale, or set by someone
weighing different things. Where an item's metadata disagrees with its consequences, it ranks by
its consequences and the ranking names the disagreement.

**An item whose problem no longer exists has no cost of delay.**
Its problem is confirmed against the current system before it ranks. One that is gone, or sits in
code nothing calls, leaves the ranking and is reported as stale with the evidence.

**Work that waits on an unmade decision ranks as that decision.**
The decision takes the work's rank, and the ranking names the work it unblocks. How deeply the
decision is then derived follows `decision-making.md`. Where several decisions wait, their order
among themselves follows `decision-making.md`.

**A ranking toward a goal includes the steps nobody has tracked.**
It compares the goal with the current state and names every step between them, tracked or not, and
ranks untracked steps beside tracked ones. While the path has untracked steps, tracking it ranks
first, after any item causing harm now, because every later ranking of the path relies on the path
being visible.

## Should

**Investigation goes deepest where a wrong rank would cost the most.**
The items near the top, and any whose metadata and consequences disagree, are checked against the
system. Items further down may rank on what their tickets say, and the ranking marks them as
unchecked.

**Work in flight ranks ahead of new work of comparable cost of delay.**
Work already started loses value each day it waits: context fades, branches go stale and conflicts
build up, while nothing it was meant to deliver reaches anyone.

**Ties and unknowns are named rather than broken silently.**
Where two items cannot be separated, or a cost of delay depends on a fact nobody has, the ranking
says so and names the fact that would separate them.

## Consider

**A slice that delivers most of a large item's cost of delay can rank far above the whole.**
This holds when most of that cost comes from one part of the item.

## In scope

- Rankings of tickets, backlog items, untracked steps toward a goal, work in flight and PRs waiting
  on review
- Any report or recommendation of what to work on next

## Out of scope

- Choosing between options for one decision, and the order of decisions that derive from one
  another: `decision-making.md`
- A project's own costs, priorities and conventions, which live in its docs and take precedence
  where they say something this file leaves open
