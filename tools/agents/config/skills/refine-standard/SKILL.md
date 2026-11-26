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

   Apply them to a worktree of `HEAD` in a directory from `mktemp -d`, never to the repo's checkout.
   First copy into it the checkout's current version of each standards file with uncommitted
   changes, so the drafts and the replays see the text the checkout holds. Then run the repo's docs
   check from the worktree's root, so a heading or line that breaks the column limit is fixed in the
   draft rather than after approval. The check lists files with git, so it fails outside a git tree
   and checks only the folder it runs from. Where an item offers options, the worktree holds the
   recommended one. Step 7 replays the worktree's files.
7. Replay the worktree's files before showing anything, so the user approves wording that has
   already caught what it should. Each round has four parts, and every agent in it is a fresh agent
   on Opus that reads its own inputs and spawns no subagents:
   - **Descriptions:** the main session writes, for each claim that changed or was added, a new
     problem it should catch, plus a clean sample with no problem, each under an opaque ID such as
     `s3`, unique for the whole run. Each describes a concrete situation, such as what the code or
     doc does, never in the words of the claim. For a claim about docs, the problem can sit in a doc
     section, such as a README's rollback steps, as the replay of `documentation.md` used. The key
     maps each ID to the claims that should catch it and their tier, listing every claim step 4
     accepted for that gap. The key stays in a folder of the main session's own and goes to no other
     agent. A revision that renames a heading changes the key's text for it, not which claims or
     tiers it lists.
   - **Samples:** an agent gets the descriptions with their IDs and nothing else, never the draft or
     the key, and writes one file per ID, named by the ID, into a `mktemp -d` folder of its own,
     with nothing in a sample that names or hints at its problem.
   - **Check:** the main session reads each sample against its description. A sample that lacks its
     problem, holds another, or hints at what is wrong with it is rewritten, or dropped when a
     rewrite still fails, and a dropped one is reported in step 8. The main session then puts the
     round's samples and every sample carried from earlier rounds into one new folder for the
     review.
   - **Review:** another agent sees only the worktree's standards README, the changed file and the
     samples folder. It reports each finding with the claim's heading and tier, lists any imperative
     left in the file, and names the claims whose wording left it unsure.

   The main session grades the review against the key. A round passes when each planted problem is
   caught at the highest tier among the claims its key entry lists, the clean sample has no
   findings, and the file has no imperative left. A problem caught under no listed claim, or at
   another tier, is a miss, and so is a clean sample with any finding. Another finding on a planted
   sample does not fail the round, but it is reported in step 8. A finding that is only the newer
   rules applied to older text elsewhere is not a miss: it is drafted as an item for the issue of
   the file it belongs to.

   After a miss, the draft is revised, and the next round uses a new reviewer on new samples plus
   every sample an earlier round missed, so the wording is not tuned to one set. A doubt the
   reviewer named can be answered in a revision too, whether or not its round missed. The key stays
   fixed: a revision of a kind step 6 sorts as the user's to decide goes to step 8 as a question
   rather than into the draft. One round of samples can be written ahead, in parallel with a review,
   while the claims and their headings stay the same. The replays stop at the first of these: a
   round passes with no revision waiting to be tested, every remaining miss waits on a question for
   the user, or five rounds have run.
8. Show the user, in one message and in their plain-speech style, every change with its current and
   new text, then the replays: for each round, what was planted, what was caught or missed, any
   sample dropped, any extra finding, each doubt the reviewer named, what changed in response, and
   any miss left at the end with why it remains. Then show each drafted issue item, as the text of
   the file it would be posted from. Every question comes last, in one numbered list with the
   recommended letter named: each change that is the user's to decide, each question with no draft,
   whether the rest of the wording is approved as shown, and whether each issue item may be posted.
   Then stop. Standards are agent instructions, so nothing is applied before the user approves the
   wording.
9. If the user's answers, or an edit the approved wording needs, such as a sentence that needs a
   general noun, bring wording the replays did not test, put it in the worktree, update the key to
   match the answers, replay the claims it touches as step 7 describes, with a limit of five rounds
   of its own, and show the new wording and its result as step 8 does. Then stop again.

   Once every word is approved, apply exactly that, as edits to the lines that change, never by
   copying a whole file over from the worktree. Other sessions may be editing the same files, such
   as an index every refinement touches, and a copied file drops their changes with no sign. Before
   applying, read `git diff` for each file: any change in it that you did not make belongs to
   someone else and stays. If a file the refinement changes, or the standards README, no longer
   matches what the worktree held, carry the drafts onto its current text and replay the claims it
   touches, as this step's first paragraph does, even when no wording changes. After applying,
   `git diff` shows your changes and theirs, and nothing of theirs lost.
10. Run the repo's full checks in a clean worktree holding `HEAD` plus only the changed files, then
    ask for the commit signal, naming each file and what changed in it. The commit message says what
    the replays planted and what they caught. After the commit, each issue item the user approved,
    in step 8 or step 9, is posted unchanged from its file on the open issue for the standards file
    it belongs to, or, where none is open, a new issue is proposed through
    `write-ticket-description`. At the end of the run, whether or not a commit was made, both
    worktrees are removed with `git worktree remove --force`, since they hold only drafts and
    copies.
