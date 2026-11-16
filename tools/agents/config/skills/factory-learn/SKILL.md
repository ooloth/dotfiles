---
name: factory-learn
description: Learn from one factory run. Given the PR or ticket a run worked on, finds the run's private record, reads its friction, transcripts, token usage and review rounds, asks how the PR fell short of the ticket, and proposes changes to the factory's skills, each with its evidence and a way to check it. Changes nothing until approved.
argument-hint: '<PR or ticket URL> [how the PR fell short]'
disable-model-invocation: true
---

Run: $ARGUMENTS

## Find the run

Find the run folder whose `run.md` names the URL:
`grep -l -F '<url>' ~/.local/state/factory/runs/*/run.md`. More than one match means the ticket was
run more than once: list each with its dates and outcome, and ask which. None means no record was
kept: say so and stop.

## Gather what went wrong

1. **My judgement.** Read the ticket with its comments, and the PR with its reviews and comments.
   Unless the arguments already say, ask me how convincingly the PR delivers what the ticket asked
   and what I would have done differently. My answer outranks everything else here, because the
   factory exists to produce the PR I would have produced. Record my answer in `run.md` as
   `- Verdict: <merged as is | merged after my changes | closed>, <one line on why>`, so runs can
   be compared on outcome as well as cost.
2. **What the run reported.** Read `run.md` and `friction.md`.
3. **What the run did.** Spawn one subagent on Opus per stage folder under `transcripts/`, because
   a loss it misses goes unnoticed. Tell each to read the transcripts itself, spawn no subagents,
   and report each place the run lost time or went wrong, citing the record: a command retried, a
   tool call or permission refused, an instruction misread or worked around, a step skipped or
   repeated, a question with nobody to ask, work later undone. Ask it also for each friction item
   the transcript does not bear out. It reports only what the transcript shows.

## Turn findings into proposals

Group the findings by cause. For each cause, find where its fix belongs, strongest first: the code
of the repo the run worked on, through a structure or API that removes the wrong option or a lint
rule or check whose error names the fix; then a scan in a review skill; and last, prose in a factory
skill, a standard, a `CLAUDE.md` or the repo's docs, or a fact recorded where agents read it. Prose
comes last because an agent can argue its way past it and cannot argue past a check. Each proposal
gives the file, the exact wording or change, the findings it answers, and how to check it: a check
is shown failing on this run's mistake, and an instruction change is checked by running the factory
again on the same ticket, or by replaying the failing input through a fresh agent given only the
changed instructions.

Read `learned.md` in the other run folders first. A cause an earlier run already got a change for
has come back, so that change did not hold: propose a stronger fix, not the same one again. A cause
no other run shows is labelled as seen once, and is proposed only when it cost this run something
large, because a rule written for one run's slip gets followed as if it always applied. Before
presenting a proposal, open each transcript record it cites yourself.

Show this run's tokens per stage and its review rounds beside the other runs in
`~/.local/state/factory/runs/`, so a run that cost far more than the others stands out.

## Present and stop

Present the proposals as numbered questions, ranked by what each would have saved this run. Change
nothing: each edit to an instruction file, and each fact recorded in a repo, waits for my approval
of its exact wording. Once I have answered, append each proposal and my answer to `learned.md` in
the run folder, so a later run of this skill knows what was already decided. A proposal whose fix is
a check or other code is drafted as a ticket in the repo where the fix belongs, instead of an edit,
and is posted once I approve its wording.
