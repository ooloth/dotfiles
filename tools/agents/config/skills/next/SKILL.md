---
name: next
description: Recommend what to work on next in the current repo, ranked by cost of delay. TRIGGER at the start of a session, or when the user asks what to work on next and you are not already partway through something.
---

Recommend one to three things to work on next, say why, and stop. The user decides. This names the
next item rather than deciding it, so reading that a repo asks for only before a decision is
skipped, and the report says so.

## Cost of delay decides

Every item is ranked by its cost of delay: the pain, slowness, loss or harm that users and
developers meet on each day the problem stays, times how often they meet it. How long the work
would take is not part of it.

Each kind of work has a cost of delay that behaves predictably, which is why kind sets the default
order below:

- **Work in flight** costs developers every day it waits: context is lost, branches go stale, and
  conflicts accumulate, while nothing it was meant to deliver reaches anyone.
- **Bugs** cause pain or harm each time someone meets them.
- **Started features** leave users without something already partly built, and the partial work
  decays like work in flight.
- **Maintenance** problems slow or mislead every later session, so fixing them before new work
  starts spares that work the cost.
- **New features** cost users the workaround they use each day without them.
- **Questions** cost nothing on their own. They carry the cost of delay of the work they block.

Kind is the default, and cost of delay is the rule it stands in for. An item moves across a kind
boundary only when you can say in one sentence why its cost of delay breaks the default, and that
sentence goes in the report.

## The repo's docs come first

Read the repo's `CLAUDE.md` or `AGENTS.md`, and the docs they point to about what to work on, how
work is tracked, and what makes a delay costly in this project. Where they state an order, a
convention or a cost, follow it and name the doc in the report. Everything below is the default for
what they leave unsaid.

## Where work lives

Find each source; none is assumed.

- **In flight:** uncommitted changes (`git status`), commits on the default branch not yet pushed,
  branches other than the default, and open PRs. A branch whose PR was closed unmerged is not in
  flight; report it for deletion.
- **Trackers:** GitHub Issues, and Jira, Linear or Trekker where the repo mentions them. Invoke the
  matching `use-*` skill before the first call. Pass a `--limit` above the largest count you expect
  to every list, because the default stops at 30 without saying so.
- **Open questions:** a folder such as `docs/questions/`, one file per question.
- **TODO and FIXME comments**, only when the repo has no tracker.

When the sources are unclear, such as two trackers that both look current, name them and ask which
to use before ranking.

Kind comes from labels. Where a repo's labels are not `bug`, `feature` and `maintenance`, map them
to those kinds and state the mapping in the report.

An issue labelled `status:agent-working` already has an agent on it and is not ranked, unless the
PR for it is closed, in which case report the label as stale. The `status:*` labels belong to the
agent PR workflows and say nothing else about priority.

## Default order

1. **Work in flight:** uncommitted changes, unpushed commits, a branch other than the default, or
   an open PR.
2. **Bugs**, by how often each one hits and how bad it is when it does, wherever they sit.
3. **Started features:** a milestone, epic or parent issue with some of its issues closed. Read its
   plan of record, which usually lives in the parent's comments rather than its body, then judge
   which item comes next from that plan, its `blockedBy` links and the current state of the code.
   That item need not be an issue yet: where the repo's docs plan work that has no issue, such as
   a milestone slice, the planned step ranks here too. Between started features, cost of delay
   decides.
4. **Maintenance.**
5. **New features**, and milestones or epics not yet started.
6. **Questions no issue cites.** Attach each one to the issue it blocks, which moves it up the
   order, or propose deleting it as obsolete. Answering a question that nothing needs yet decides
   it before the information that would improve the answer exists.

A started milestone or epic lifts only its feature work. Its bugs and maintenance rank by their own
kind, so a milestone of maintenance work does not make its issues rank as a started feature.

**Issues with no kind** cannot be ranked, and a bug among them goes unranked. Rank what you can, and
give a title that reads as a bug the bug rank while it waits. At the end of the report, propose a
kind for each, or propose closing it as obsolete or as a duplicate, saying what you checked. Read
the body only when the title leaves it unclear. Apply nothing until the user approves the batch.

Who filed an issue does not affect its rank. Within a rank, weigh how often the problem affects
someone and how bad it is when it does.

## Before recommending

Check these only for the candidates you are about to recommend, never across the whole tracker.

- **A decision comes first.** If a candidate depends on a decision nobody has made, that decision
  takes the candidate's rank, and the report names the work it unblocks. An unmade decision appears
  as a question file the issue or planned step cites, or as an open decision recorded in the issue
  or its comments.
  Read the cited file and the comments to judge whether the dependency is real, since a citation
  alone can be background.
- **The problem still exists.** Confirm it against the code. An issue whose problem is gone, or sits
  in code nothing calls, has no cost of delay.
- **Nobody has started it.** Read the issue's state, comments and relationships rather than its
  body, which is a brief and cannot show whether anyone began.

## Report

For each recommendation, three or four lines: the item, its rank, and the sentence of evidence that
decided it, including any cost-of-delay sentence that moved it across a kind boundary. Name the
repo docs you followed and anything you skipped. Name anything ambiguous, such as two started
features whose next items tie on cost of delay, rather than picking.

End by offering `scan-ideas` for a ranking of the whole backlog. If nothing is left anywhere, say so
and offer `scan-gaps`.
