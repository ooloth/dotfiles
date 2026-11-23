---
name: refine-standard
description: Bring one file in the standards folder up to the bar documentation.md, correctness.md and testing.md meet. It opens with its category's best possible safety, performance and experience, its claims follow from that opening and meet the standards README's phrasing rules, and a replay through a fresh agent shows the claims catch what they should. Use when asked to refine, open or audit a standards file.
argument-hint: '<standards file, such as security.md>'
effort: high
model: opus
---

## What this is for

A standards file is what a reviewer grades code against. When its claims follow from what the
category is for, the reviewer finds the failures that matter, grades each one once, and finds
nothing in sound code. When the claims were written one at a time, real failures go unnamed and the
same gap gets graded at two tiers.

So each file opens with its category's best possible safety, performance and experience, as
`decision-making.md` defines them, and every claim follows from that opening. `documentation.md`,
`correctness.md` and `testing.md` are the worked examples. Read their openings, and the commits that
refined them (`git log --format='%h %s' -- tools/agents/config/standards/<file>`), before starting.

## Steps

1. Read the standards `README.md` (the tiers and the Phrasing rules), `decision-making.md` (the
   three properties), `documentation.md` and the target file, all in full. Read the open issue for
   the target file too: earlier passes leave items there.
2. List how code or a system in this category can fail, under each property in turn: how it goes
   wrong or causes harm, how it is slow, and how it is hard to use or change. Write the list before
   reading the file's claims closely, because the list is what finds gaps.
3. Write the opening: the category's best possible safety, performance and experience. Where the
   category barely bears on one of them, say so in a sentence, with the reason.
4. Check each claim against the opening and the list: which failure it catches, and at which tier. A
   failure no claim catches is a gap. Two claims that catch one gap are fine when one adds detail,
   because the higher tier decides. Two claims whose exemptions disagree are not.
5. Check each claim's wording against the Phrasing rules and `documentation.md`. The usual misses:
   an imperative in a body, a list of examples not marked as examples, a product named where a
   general term holds, an incident told as evidence, a figure with no source, an absolute with an
   exception, and a sentence that doesn't read in one pass when said aloud.
6. Draft every change as its exact current text and its new text, and sort them:
   - **Yours to decide:** marking examples, a general term for a product, removing an incident,
     rewrapping, fixing grammar.
   - **The user's to decide:** a new claim, a deleted claim, a changed tier, any change to the
     README rules, anything that changes how a reviewer grades a gap, and a change that softens or
     strengthens what a claim requires, such as replacing never with rather than.

   Every item carries its exact new text; a question with no draft goes to the user as a question,
   with lettered options.

   Show all of them together, in the user's plain-speech style, and stop. Standards are agent
   instructions, so nothing is applied before the user approves the wording.
7. Apply exactly what was approved. If an edit forces wording the user didn't see, such as a
   sentence that needs a general noun, show it before committing.
8. Replay through a fresh agent on Opus that sees only the README, the changed file and its inputs:
   - a sample with one planted problem for each claim that changed or was added
   - a clean sample as a control
   - for a claim about docs, the README rollback sections used for `documentation.md`

   It passes when every planted problem is caught under the intended claim and tier, the control
   has no findings, and the file has no imperative left.
9. Stop once a replay finds only the newer rules applied to older text elsewhere, rather than a
   miss. Put each such item on the issue for the file it belongs to.
10. Run the repo's full checks in a clean worktree holding `HEAD` plus only the changed files, then
    ask for the commit signal, naming each file and what changed in it. The commit message says
    what the replay planted and what it caught.
