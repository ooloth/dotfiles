---
number: 014
status: accepted
date: 2026-11-15
---

# 014 — A factory run's record is a local folder named by the planning session's ID

## Forced by

The factory learns from each run ([#268](https://github.com/ooloth/dotfiles/issues/268)). What it
learns from, the friction each agent reports, the session transcripts, the token usage and the
number of review rounds, must outlive the run and its PR. Claude Code deletes a transcript after 30
days. Nothing about a run may reach a PR, a commit or a ticket, because work PRs are read by a team
and this repo is public ([#291](https://github.com/ooloth/dotfiles/issues/291)).

## Decision

Each run of `factory-ticket-to-pr` keeps its record in `~/.local/state/factory/runs/<run-id>/`, on
the machine that ran it and outside every repo. The run ID is the planning session's ID. The folder
holds `run.md` (the ticket, the PR, and each stage's session ID, times, outcome, token usage and
review rounds), `friction.md` (every stage's and subagent's Friction list) and `transcripts/`, where
each stage copies its own and its subagents' transcripts as its last step. `factory-learn` finds a
run by searching the `run.md` files for its PR or ticket URL.

## Rejected

- **A folder per ticket.** It needs no new identifier. It is rejected because a second run of the
  same ticket would overwrite the first.
- **A SQLite table.** It would make queries across runs easy. It is rejected because it adds a
  schema, and a query tool for what is mostly prose, where a folder of Markdown files is read with
  the tools agents already use.
- **A private git repo.** It would back the records up and let them travel. It is rejected because
  work transcripts would leave the machine.
- **Transcripts left in place, with `cleanupPeriodDays` raised.** It copies nothing. It is rejected
  because every session's retention would change, not just the factory's.

## Revisit when

A team shares the factory, so one person's friction should reach everyone's runs.
