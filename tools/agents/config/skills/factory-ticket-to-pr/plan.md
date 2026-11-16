# Planning stage

The ticket is the first argument, and `plan-only` may follow it. Tell every subagent also to change
nothing in the repo.

## 1. Check the inputs

Create the run folder and start `run.md` with its header and a `plan` section, as "The run
record" in `SKILL.md` says.

Read the ticket with all its comments (`gh issue view <n> -R <repo> --json
title,body,comments,parent`). When `parent` is set, read that issue with its comments too.
If it already has an approach or design comment, escalate: this skill plans tickets that have none.

## 2. Approach: three lenses, reconciled, then challenged

### Three runs, one lens each

Spawn three subagents in one message. Give each the ticket reference, the repo path, the path of
the `discuss` skill (`~/.claude/skills/discuss/SKILL.md`) and one lens: **safety**, **performance**
or **experience**, as `~/.agents/standards/decision-making.md` defines their maximums. Tell each to:

- follow the skill's Phases 1 to 3, stating its recommended answer wherever the skill says to ask;
- consider only options that meet every binding property, and among those find the ones that come
  closest to its lens's maximum. If its lens does not bind on this ticket, say so in one line and
  use the lens **smallest change** instead: the fewest behaviours changed, files touched and lines
  that still meet every binding property;
- look past the ticket's wording for the cause of the problem it describes, since a ticket often
  names a symptom. Prefer an option that fixes the cause when it is within reach. A cause-level fix
  outside this ticket's scope goes under **Deferred** rather than being dropped;
- run `git log` and `git blame` on the lines it would change, to tell a slip from a choice someone
  made on purpose;
- return each option in the same form: the mechanism in one line, how it delivers each binding
  property, its effect on safety, performance and experience, and the command that showed each
  claim.

Do not share one run's output with another.

### Reconcile

1. List every risk any run raised and which runs raised it. Check each against the code, by running
   it where you can. Keep every risk that is real, however many runs missed it.
2. List every fact the runs disagree on, and settle each by running a command. Keep the command and
   its output.
3. Build one target-properties list from the reconciled risks and facts, and apply `discuss` Phase
   4's review of claims to it.
4. Merge options that share a mechanism, then score every distinct option against every binding
   property and against the safety, performance and experience maximums, in one table.
5. Before choosing, look for a combination of parts of different options that comes closer to all
   three maximums than any single option. A tradeoff left standing names the fact that forces it.

### Choose, with evidence

1. If one option meets every binding property and is at least as good as every other on all three
   maximums, choose it, and record in one line why each other option loses.
2. Otherwise, run one challenge round. Spawn two subagents on Opus in one message, because a case
   either one misses goes unnoticed: one argues the strongest
   case for the runner-up, and the other tries to show the leader fails a binding property. Each
   must back every claim with a command it ran, a concrete failing scenario or a property shown to
   break, or report "no evidence found". Drop claims without evidence, then choose.
3. Whichever way the choice was made, spawn one subagent on Opus to attack it, because a scenario
   it misses goes unnoticed: find a scenario where the
   chosen approach breaks a binding property, or a risk no property covers, under the same evidence
   rule. A real finding goes back into step 4 of the reconciliation; "no evidence found" stands.
4. Write the **Assumptions**: the approach-level assumptions the choice rests on that, if wrong,
   would put a different option first, such as what the system is for, who calls it or what may
   change. Leave out code-style and refactoring preferences: they are not what an approach rests
   on. The strongest argument that lost tells you where to look for them.
5. Settle the remaining open decisions under "Decisions nobody made".

Post the approach comment now, before any design work, so the plan is visible and durable while
design runs. Follow "How the comments read" below.

Then print a short summary in this session: the approaches weighed, the one chosen and the property
that decided it, and each decision taken without review. Anyone looking at this window should be
able to tell what is being designed without opening the ticket.

## 3. Design: three lenses, reconciled

Spawn three new subagents in one message. Give each the ticket reference, the repo path, the path
of the `design` skill (`~/.claude/skills/design/SKILL.md`) and one lens (safety, performance or
experience, with smallest change as the fallback, as in step 2). Tell each to read the agreed
approach from the approach comment on the ticket, not from you, so design works from the same text
implementation will read. Tell each to follow the skill's Phases 1 to 6, including Phase 2's
comparison of two or three type progressions scored against the properties, to state its
recommended answer wherever the skill says to ask, to run `git log` and `git blame` on the lines
its design touches, and to return its design, with every claim about how code or a test setup
behaves beside the command that showed it.

Then reconcile their outputs yourself:

1. List every constraint, failure variant and test any run proposed, and which runs proposed it.
   Keep each one that observes a target property or a real risk, however many runs missed it.
2. List every claim the runs disagree on, such as whether a setup takes effect or what a function
   returns, and settle each by running a command. Keep the command and its output.
3. Score every progression any run proposed in one table, so the chosen one is compared with the
   others rather than taken as given.
4. Build one design from the reconciled result, not from any one run's design, and settle its open
   decisions under "Decisions nobody made".

If design needs an escalation, the approach comment stays on the ticket and the escalation comment
follows it.

## 4. Post the design

Post the design comment, following "How the comments read" below. Keep the approach comment's
property numbering.

## How the comments read

Write the approach comment as the `discuss` skill's Phase 4 describes its ticket comment, and the
design comment as the `design` skill's Phase 7 describes its ticket comment, adding only the
`Decided without you` section below. Name no skill, command or agent in either: say what happened
instead. Evidence and reasoning stay in this session; the comments carry only the decision.

When you took a one-way decision, the comment that records it has a `## Decided without you 🧷`
section: in the approach comment right after "Decided by", in the design comment as its last
section. One entry per decision: what was decided, in one line; the options weighed; the reason it
won; and what would reopen it. It is where the user checks what was decided for them before the
draft PR merges. Planning commits nothing, so a decision taken here has no record yet: its entry
stands in for the record link the `design` skill asks for, and the implementation writes the
record from it.

## 5. Start the implementation

Before printing any final line below, finish the run record.

If the arguments include `plan-only`, skip this step and print `PLANNED: <link to the design
comment>; implementation not started (plan-only)` as the final line.

If a `Decided without you` entry adds a new dependency or external service, skip this step too,
because the implementation would install or call it before the user has seen the choice. Print
`PLANNED: <link to the design comment>; implementation not started: <the dependency or service>
waits for review. Start /factory-ticket-to-pr build <owner/repo#issue> <run-id> once you approve
it` as the final line.

Find the main checkout with `git rev-parse --path-format=absolute --git-common-dir`; its parent
directory is the repo root. Pick a worktree name `afk-<issue>`, adding `-2`, `-3` and so on if
that name is already under `<repo root>/.claude/worktrees/`. Then run:

```
tmux new-window -d -n <worktree name> -c <repo root> "bash ~/Repos/ooloth/dotfiles/tools/claude/cc.bash --unattended -w <worktree name> '/factory-ticket-to-pr build <owner/repo#issue> <run-id>'"
```

`--unattended` comes first, as `cc.bash` requires, and starts the session in auto mode on every
machine, never in bypass mode, because nobody watches it and it reads ticket text other people
wrote.

Confirm with `tmux list-windows` that the window exists. Print
`PLANNED: <link to the design comment>; implementation started in tmux window <worktree name>` as
the final line.
