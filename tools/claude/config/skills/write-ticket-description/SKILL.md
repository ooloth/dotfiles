---
name: write-ticket-description
description: Voice guide for writing issue/ticket/task/epic descriptions. Use this skill for ALL issue creation — GitHub issues, Jira tasks, Monday tasks, Linear tasks, and epics. Contains section structure, voice rules, and anti-patterns. Never write ticket descriptions without invoking this skill first.
allowed-tools: [Bash, Read, Glob, Grep]
---

# Writing Ticket Descriptions

## ⚡ QUICK START

1. Explore the relevant code to verify the current state before describing it
2. Draft using the template and voice rules below
3. Create the ticket using the appropriate platform tool

---

## Title Rules

- **Scannable in a list** — the reader understands what it is without opening it
- **Outcome-focused, not implementation-focused** — "Cache status data for fast reads" not "Add SQLite table for status"
- **Verb-first or noun-first, not a full sentence** — "Add daemon for background status refresh" or "Background status refresh via daemon"
- **Specific enough to distinguish from similar tickets** — "Fix auth token expiry on mobile" not "Fix auth bug"

❌ Vague: "Fix status", "Improve performance", "Refactor auth"
❌ Implementation-first: "Add tokio-cron-scheduler", "Create new table"
❌ Passive: "Status should be cached", "Daemon is needed"

---

## Template

```markdown
## Why

[One sentence: what problem this solves and why it matters now. User-facing or developer-facing — not "tech debt".]

## Current state

[What exists today and what's wrong with it. Observable facts, not opinions.]

## Ideal state

[Bullet list of observable behaviors when done. Written as user-facing or developer-facing facts — not implementation steps. Each bullet should be independently verifiable.]

## Out of scope

[Explicit list of things that might seem related but aren't part of this issue. If nothing obvious qualifies, omit this section.]

## Starting points

[2-3 file paths the implementer should read first. Helps a cold reader orient fast.]

## QA plan

[Numbered steps an implementer can follow cold to confirm correctness. Specific enough to run without asking anyone. No automated tests — manual e2e only.]

## Done when

[One-line bar: the minimum condition for this issue to be closeable.]

## Depends on

[Optional. List issues that must be complete before this one can start, with a one-line reason each is a hard prerequisite. Omit if no hard dependencies exist.]
```

---

## Voice Rules

### Why section

- One sentence only — what problem this solves AND why it matters now
- User-centric framing when possible; developer-centric is fine when the user isn't affected
- Never write "tech debt" or "code quality" as the reason — name the actual downstream impact

### Current state

- Observable facts only — what a person can see or measure today
- Don't editorialize ("unfortunately", "badly", "messy")
- Keep it to 2-4 sentences max

### Ideal state

- Write each bullet as a fact that will be true when the work is done: "X does Y" not "add X" or "implement Y"
- Each bullet should be independently checkable
- Don't mix in implementation steps — those belong in a PR, not an issue

### Out of scope

- Be explicit about adjacent things that are NOT included
- Prevents scope creep and spares the implementer from guessing
- Omit this section if nothing obvious qualifies

### Starting points

- Name actual file paths, not directory names
- Pick the files a reader would need to understand the current behavior, not every file that will change
- 2-3 max; more than that is noise

### QA plan

- Numbered sequential steps, each building on the last — reads like a walkthrough
- Every step ends with what the implementer should observe: "Expect to see X"
- No automated steps (no "run tests", "run CI") — manual e2e only
- Include failure/edge cases, not just the happy path

### Done when

- One sentence
- States the minimum bar, not the ideal
- Phrased as a condition: "when X is true" or "once X works"

### Depends on

- List only hard prerequisites — issues this cannot start without, not issues it would merely benefit from coming after
- One line per dependency: issue reference + why it blocks
- Omit entirely if no hard dependencies exist

---

## What NOT to Do

❌ Describing implementation steps in "Ideal state" — those belong in a PR
❌ Vague "Why" like "improve code quality" or "refactor for maintainability" — name the impact
❌ Omitting "Out of scope" when adjacent things could easily be pulled in
❌ QA steps that reference automated checks — always manual e2e
❌ QA steps that don't say what to observe — every step needs an expected outcome
❌ Starting points that name directories instead of files
❌ "Done when" that lists multiple conditions — pick the one that matters most

---

## Example: Good Ticket Description

```markdown
## Why

`hub status` hits GitHub on every invocation, which will block the TUI from rendering without a network round-trip.

## Current state

`hub status` fetches live GitHub data (PRs, issues) on every call. There is no background refresh, no caching, and no store schema for status data.

## Ideal state

- `hub daemon` runs as a long-lived process and refreshes status data on a configurable schedule
- Each refresh writes results to SQLite via `store/`
- `hub status` reads from the cache — instant output, no network call
- If the cache is empty or stale beyond a threshold, `hub status` falls back to a live fetch with a warning
- The daemon is the only process that writes status data; the CLI only reads

## Out of scope

- Running the daemon as a system service (launchd/systemd) — out of scope for now
- Scheduling workflows other than status

## Starting points

- `ui/cli/src/main.rs` — CLI entry point and command dispatch
- `workflows/src/status.rs` — current live-fetch logic
- `store/` — existing SQLite pattern to follow

## QA plan

1. Start `hub daemon`, wait for the first tick — expect to see status rows in SQLite
2. Run `hub status` immediately after — expect instant output (no network delay)
3. Kill GitHub connectivity, trigger a daemon tick — expect graceful failure with no corruption of existing cache rows
4. Run `hub status` with an empty cache — expect a live fetch and a warning that the cache was empty
5. Manually backdate cache rows, run `hub status` — expect a staleness warning
6. Stop `hub daemon` — expect clean shutdown with no panics

## Done when

`hub status` reads from a SQLite cache populated by `hub daemon` and falls back gracefully when the cache is missing or stale.
```

### Why This Works

✅ Why names the actual downstream impact (TUI blocking), not just "improve performance"
✅ Current state is observable facts, not opinions
✅ Ideal state uses "X does Y" framing — each bullet is a verifiable fact
✅ Out of scope prevents two obvious scope-creep traps
✅ Starting points are file paths, not directories
✅ QA steps are sequential and each ends with an expected observation
✅ Done when is a single condition, not a checklist
