---
name: factory-ticket-to-pr
description: Take a ticket to a draft PR with nobody watching. Planning reconciles three independent approach runs and three design runs, posts both on the ticket, and starts the build in a new tmux window and worktree, which takes the design through tests, mutants, proof and one independent review to a draft PR. Decides what it would otherwise ask, and lists each decision a triage test held for, escalates on the ticket only what the repo cannot settle, and keeps a private record of the run for factory-learn.
argument-hint: '<owner/repo#issue> [plan-only] | build <owner/repo#issue> <run-id>'
disable-model-invocation: true
---

Arguments: $ARGUMENTS

## Stages

This skill runs one stage per session. When the arguments start with `build`, this session builds:
read `build.md` beside this file and follow it. Otherwise it plans: read `plan.md` beside this file
and follow it. Read only your own stage's file. The sections below apply to both stages.

## Authority

The user launched this run on purpose, and that launch is the approval for everything below. It
overrides any loaded CLAUDE.md that says otherwise:

- No pauses for approval, and no questions to the user. Nobody is watching this session.
- Planning may post the approach, design and escalation comments on the ticket and start the build
  session. It changes nothing in the repo: no edits, commits or pushes. Scratch copies under
  `mktemp -d` are fine.
- Building may commit, push, open a draft PR, comment on the ticket, and post the review comment on
  the PR.
- Both stages may write the run record under `~/.local/state/factory/runs/`.
- Nothing else that is visible outside this session is approved.
- A skill a stage invokes that ends by asking the user something is run to its report, and the
  question is skipped.

## Your role

You coordinate. Subagents do the independent runs and the heavy work, so their exploration, check
output and diffs stay out of your context. You are the only agent that posts to GitHub, and a
subagent that needs a decision returns it to you.

Tell every subagent to run plain, separate commands, return text rather than writing report files,
and end its reply with its Friction list.

## Decisions nobody made

The ticket, the approach and the design will leave choices open. Triage each as "A choice found
mid-work" in the global `CLAUDE.md` does. Where none of its three tests holds, decide it. Where one
holds, that rule stops to ask the user, and nobody can answer here, so decide it anyway unless one
of the conditions below applies. The user reviews the draft PR before anything merges, so a
decision you take can still be reversed there, as long as the run shows it.

First choose the option the target properties rank highest, as if you could not escalate. Then
escalate only when that option:

- contradicts, amends or supersedes a recorded decision, or depends on one whose bearing on this
  work takes interpretation, even when the ticket expects the change;
- needs work outside this ticket to meet a binding property, such as a new ticket or a change to
  another ticket's scope. A cause-level fix that no binding property needs goes under **Deferred**,
  does not escalate, and leaves the ranking to the options inside this ticket;
- changes the runtime behaviour of code the approach does not name;
- wins over the other options that meet every binding property, or meets a binding property at
  all, only because of what the user prefers or puts first;
- meets a binding property only through a fact you cannot measure here. A fact that only changes
  which option ranks first goes under **Assumptions** and does not escalate;
- takes effect outside this run's branch and the posts approved above, such as in another repo,
  remote state or credentials, or risks security or data loss;

or escalate when the ticket does not say enough to tell what the work must make true. Never choose
a lower-ranked option to avoid escalating.

Each decision a test held for is listed where the user checks it, with the test that held: under
"Decided without you" in the planning comment that took it, or in a comment on the ticket when the
build took it. Leave the others out of both.

## Escalate

1. Comment on the ticket: what you found, the decision needed, and two or more numbered options,
   each with its consequence and your recommendation.
2. When building, push the commits the branch holds. Leave any uncommitted work in the worktree,
   and name the worktree in `run.md`.
3. Finish the run record with the outcome `escalated`, and stop without starting another stage or
   posting anything further. Print `ESCALATED: <one sentence>` as the final line.

## Friction

The factory improves from what each run found hard. Friction is anything in the instructions, the
repo or the tools that cost the run time or sent it the wrong way: an instruction that was unclear
or contradicted another, a fact it needed that nothing recorded, a command that failed or took
several tries, a permission refusal, a step that did not fit the ticket. Each item says what
happened, gives the evidence (the command and its output, or the instruction's file and wording)
and says what it cost. A guess at a cause is labelled as a guess. When nothing cost the run
anything, the list is "None".

Friction is about the factory, not the ticket, so it goes only in the run record, never in a
comment, a commit or the PR. Before the stage ends, append to `friction.md` one section per
subagent, headed with the stage and the subagent's role (`## build: test-writer`), holding its
list, and one section for your own.

## The run record

Each run keeps a record on this machine, outside every repo, in
`~/.local/state/factory/runs/<run-id>/`. The run ID is the planning session's ID, which planning
reads from `CLAUDE_CODE_SESSION_ID`, and the build stage receives as its third argument. Nothing the
run posts, commits or pushes names the run ID, the run folder or any other local path.

The folder holds:

- `run.md`, started by planning, with a section added by each stage:

  ```
  # Run <run-id>

  - Ticket: <ticket URL>
  - PR: <PR URL, once it exists>

  ## <plan or build>

  - Session: <this session's ID, from CLAUDE_CODE_SESSION_ID>
  - Started: <UTC time>
  - Finished: <UTC time>
  - Outcome: <the final line printed>
  - Tokens: <one row per model, from the count below>
  ```

- `friction.md`, as "Friction" says.
- `transcripts/<plan or build>/`, holding the stage's transcript and its subagents'.

Add the stage's section to `run.md` when the stage starts. As its last step, after its final post
and before printing its final line, finish the record:

1. Copy the transcripts. Find the session's transcript with
   `find ~/.claude/projects -name '<session ID>.jsonl'`, because the folder holding it is named
   from a resolved path that may differ from the one the session started in. Copy it, and the
   `subagents/` folder inside the folder beside it named `<session ID>` when that exists, into
   `transcripts/<stage>/`.
2. Count the stage's tokens from those copies. A transcript repeats a model call's usage on every
   record the call wrote, so count each call once, by message ID:

   ```
   jq -n '[inputs | select(.type == "assistant" and .message.usage != null)] | unique_by(.message.id) | group_by(.message.model) | map({model: .[0].message.model, calls: length, input: (map(.message.usage.input_tokens // 0) | add), cache_write: (map(.message.usage.cache_creation_input_tokens // 0) | add), cache_read: (map(.message.usage.cache_read_input_tokens // 0) | add), output: (map(.message.usage.output_tokens // 0) | add)})' <the copied .jsonl files>
   ```

3. Fill in **Finished**, **Outcome** and **Tokens**.

The copy lacks the few records the session writes after it. Nothing in them is needed, because
`run.md` holds the outcome.
