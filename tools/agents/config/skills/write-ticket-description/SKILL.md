---
name: write-ticket-description
description: Voice guide for writing issue/ticket/task/epic descriptions. Use this skill for ALL issue creation — GitHub issues, Jira tasks, Monday tasks, Linear tasks, and epics. Contains section structure, voice rules, and anti-patterns. Never write ticket descriptions without invoking this skill first.
allowed-tools: [Bash, Read, Glob, Grep]
---

# Writing Ticket Descriptions

## ⚡ QUICK START

1. **Duplicate check** — search the platform for issues with similar titles; read candidate
   descriptions; stop only if a duplicate or overlap is found — otherwise say "No duplicates found"
   and continue (see [Duplicate Check](#duplicate-check) below)
2. Explore the relevant code to verify the current state before describing it
3. Check the project's recorded decisions for any that constrain this work, and note any one-way
   decision the work needs that nobody has made (see [Decisions](#decisions))
4. Ask the requester, before drafting, for any bound, exclusion or desired property you would
   otherwise have to invent (see [Ideal state](#ideal-state) and [Out of scope](#out-of-scope)) —
   never for an architectural choice
5. Draft using the template and voice rules below
6. Create the ticket using the appropriate platform tool

---

## Duplicate Check

Before writing anything, search the platform for issues that may already cover this ground.

### Step 1 — Search for similar titles

Use the platform's search to find issues whose titles sound similar to the one you're about to
create. Cast a wide net: try multiple keyword combinations drawn from the problem domain, not just
the exact phrasing the user gave you.

**GitHub:**
```bash
gh issue list --search "KEYWORDS" --state all --limit 20 --json number,title,state
```

**Linear:** use the Linear MCP search tool with keyword queries.

**Jira / Monday:** use available CLI or MCP tools; fall back to asking the user to paste relevant
results if no tool is available.

### Step 2 — Read candidate descriptions

For any issue whose title overlaps meaningfully, fetch the full description and read it. Titles
alone are not enough — two issues can sound similar but cover different root causes, or the same
root cause from different angles.

**GitHub:**
```bash
gh issue view NUMBER --json title,body,state,url
```

**Linear / Jira / Monday:** fetch the full issue body via the relevant tool.

### Step 3 — Recommend one action

Based on what you find, recommend exactly one of the following and explain why:

| Situation | Action |
|---|---|
| Existing issue covers this fully, description is complete | **Stop** — tell the user, link the existing issue, do not create a new one |
| Existing issue covers the same problem but the description lacks context, clarity, or scope | **Stop** — propose specific edits to the existing description and wait for approval |
| Existing issue is correct and complete, but new context or examples should be captured | **Stop** — propose a comment on the existing issue and wait for approval |
| No meaningful overlap found | **Continue** — say "No duplicates found" and proceed to the next quick-start step without pausing |

---

## Epics and Sub-Issues (GitHub only)

Applies when GitHub Issues is the ticketing system. Linear, Jira and Monday have their own
parent/child mechanics — use their native tools instead.

GitHub's official **sub-issue** feature is what to reach for, not task-list checkboxes. Sub-issues
give the parent a real progress bar, give each child a visible parent, and survive renumbering.
Checkbox lists (`- [ ] #12`) are the fallback only when the sub-issue API is unavailable.

### Creating the hierarchy

`gh issue create --parent PARENT_NUMBER` creates a child already linked to its parent (gh 2.102).
To link an issue that already exists, use `gh issue edit CHILD_NUMBER --parent PARENT_NUMBER`, or
`gh issue edit PARENT_NUMBER --add-sub-issue 12,13` for several at once. Both take an issue number
or URL, and `--blocked-by` / `--add-blocked-by` record a blocking relationship the same way.

### Verifying the link

```bash
gh issue view PARENT_NUMBER -R OWNER/REPO --json subIssues,subIssuesSummary
gh issue view CHILD_NUMBER -R OWNER/REPO --json parent
```

These fields are printed only when requested by name; default `gh issue view` output shows no
relationships, so their absence there says nothing about whether the link exists. `subIssues`
comes back as `{nodes, totalCount}`, not a list, so a filter reads `.subIssues.nodes[].number`.

### Writing an epic body

An epic uses the same template as any other ticket, with two additions:

- **A coverage table** mapping each externally-defined requirement (a spec, a brief, a checklist in
  a README) to the sub-issue that satisfies it. This is what makes "did we miss anything?"
  answerable at a glance. Fill the numbers in *after* the children exist, then edit the epic.
- **A note naming any sub-issue that has no corresponding requirement** and why it earns its place.
  Unexplained extra scope in an epic reads as scope creep.

Keep the epic's own Ideal state about the aggregate — all children closed, all requirements met —
never about the implementation of any one child.

### Ordering

Create the parent first so children can reference it, and open each child body with `Part of #N`.
Sub-issues list in creation order, so create them in the order you intend to work them.

---

## Title Rules

- **A claim about what will be true once the work is done**, in the present tense — "Large order
  exports download without timing out"
- **Scannable in a list** — the reader understands what it is without opening it
- **An outcome, not a mechanism** — the claim describes what a user or developer experiences, not
  how the system achieves it
- **Specific enough to distinguish from similar tickets** — "Mobile users stay signed in after
  switching apps" not "Sign-in works"

❌ Vague: "Exports work", "Performance is better", "Auth is cleaner"
❌ Task: "Add background export job", "Fix auth bug"
❌ Wish: "Exports should not time out"
❌ Mechanism: "Exports run on a job queue", "Status is cached in SQLite"

---

## Template

```markdown
## Current state

[Lead with the downstream impact, then support it with the observable facts that cause it. No opinions.]

## Ideal state

[Bullet list of observable behaviors when done. Written as user-facing or developer-facing facts — not implementation steps. Each bullet should be independently verifiable.]

## Out of scope

[Only exclusions the requester stated. Omit this section when they stated none.]

## Decisions

**Constraints**

[Each recorded decision this work must respect, linked, with one line on how it binds this work.]

**Open**

[Each one-way decision this work needs that nobody has recorded, phrased as a question, with the category that makes it one-way.]

## Starting points

[2-3 file paths that explain today's behavior. Helps a cold reader orient fast.]

## Depends on

[Optional. List issues that must be complete before this one can start, with a one-line reason each is a hard prerequisite. Omit if no hard dependencies exist.]
```

---

## Voice Rules

### Current state

- Lead with the consequence: one sentence naming the downstream impact
- Follow with the observable facts that cause it — what a person can see or measure today
- Don't editorialize ("unfortunately", "badly", "messy")
- Keep it to 2-4 sentences max
- Whoever re-verifies it after the ticket was created adds a `Checked YYYY-MM-DD` line; a new ticket
  needs none, since the platform records its creation date

### Ideal state

- Write each bullet as a fact that will be true when the work is done: "X does Y" not "add X" or
  "implement Y"
- Each bullet is something a person can check in the running system when the ticket closes — these
  bullets are what make success observable
- A business outcome (fewer support tickets, happier customers) appears only as the reason for a
  system bullet, after "so that", and only when the link is not obvious
- Where a property has a limit (a size, a time, a count), the bullet states the most demanding value
  wanted: "An export of up to 1,000,000 orders completes"
- Only the requester supplies a limit. If a property needs one and you do not know it, ask before
  drafting; never invent a plausible number
- A yes-or-no property gets no limit
- Ideal state is the full scope: anything it does not describe is out of scope
- So each bullet traces to something the requester said. A property you think the work should also
  have is a question for the requester before drafting, not a bullet
- Ideal state is also the bar for closing: the ticket closes when every bullet holds
- Don't mix in implementation steps — those belong in a PR, not an issue
- The step-by-step verification plan is written during implementation, once the approach is known,
  not here

### Out of scope

- List only exclusions the requester stated; each one is a decision, and deciding is not the
  author's job
- An exclusion you think of yourself is a question for the requester before drafting, not a bullet
  in the ticket
- Omit this section when the requester stated no exclusions

### Decisions

- Look for recorded decisions in `DECISIONS.md`, `docs/decisions/`, `docs/adr/`, `doc/adr/`, `adr/`
  and `docs/architecture/decisions/`, and search the repo for "ADR"
- A project may record decisions somewhere else, so also check its `CLAUDE.md`, `AGENTS.md`,
  `README.md` and `docs/README.md` for where it says decisions live
- Read titles first; open a record only when its title touches this work
- Under **Constraints**, link each record that binds this work and say in one line how it binds.
  Don't restate its reasoning; the record is the source
- A record binds only when its title plainly covers this work. When applying it takes interpretation
  (does a record about "customer downloads" cover an export only admins can run?), deciding whether
  it applies is itself a decision: link the record under **Open** as that question instead of
  asserting it binds
- If the request conflicts with a recorded decision, say so under **Constraints** and do not resolve
  it. Following the request instead needs a new decision that supersedes the record, and that goes
  under **Open**
- Under **Open**, list a decision only when the work would introduce one of these: a new external
  service or dependency; a new persistent data shape or store; a new public interface (an API, an
  event, a CLI contract, a file format); a new process or runtime; a user-facing pattern people will
  learn. Any other choice belongs to the implementer and is not listed
- Phrase each open decision as a question and name its category. Name options only if the requester
  did, and never choose one
- An open decision is settled through the project's decision process (a decision record, an ADR),
  not by the requester in chat. The requester may answer what users get; how the system provides it
  stays open. On a project tracked in Jira, Linear or similar, suggest a decide task on that
  tracker for each open decision; suggest a `docs/questions/` file only on a personal project
- When a list is empty, say so and name where you looked: "No recorded decisions found in
  `docs/decisions/`, `DECISIONS.md` (searched for ADR)." / "No open decisions."

### Starting points

- Name actual file paths, not directory names
- Pick the files a reader would need to understand the current behavior, not the files where the
  change should go
- 2-3 max; more than that is noise

### Depends on

- List only hard prerequisites — issues this cannot start without, not issues it would merely
  benefit from coming after
- One line per dependency: issue reference + why it blocks
- Omit entirely if no hard dependencies exist

---

## What NOT to Do

❌ Hard-wrapped prose in a GitHub issue — GitHub shows each newline as a line break, so a wrapped
paragraph renders as ragged short lines; write each paragraph and list item as one line
❌ Describing implementation steps in "Ideal state" — those belong in a PR
❌ Current state that opens with a technical fact instead of the downstream impact
❌ Burying the consequence — "the export runs synchronously" before "large customers cannot export"
❌ An exclusion in "Out of scope" that the requester did not state
❌ A limit in "Ideal state" that the requester did not supply
❌ An "Ideal state" bullet that can only be checked outside the system ("support gets fewer tickets")
❌ An "Ideal state" bullet the requester did not ask for
❌ A ticket that contradicts a recorded decision without saying so
❌ An open decision answered in the ticket, or put to the requester as a chat question
❌ A choice the implementer can easily reverse listed as an open decision
❌ A QA plan or verification steps — they assume an approach nobody has chosen yet
❌ Starting points that name directories instead of files, or point to where the change should go

---

## Example: Good Ticket Description

```markdown
# Large order exports download without timing out

## Current state

Customers with more than about 50,000 orders cannot export their order history, and support receives several tickets a week asking for exports to be run manually. The export request fails with a timeout after 30 seconds for any account above that size, and the page shows a generic error with no suggestion of what to do next.

## Ideal state

- An export of up to 1,000,000 orders completes and the customer receives the file
- A customer who starts a long export can leave the page and still get the file when it is ready
- A customer can see whether an export is still running, finished, or failed
- A failed export tells the customer it failed and lets them start it again

## Out of scope

- New export formats (only the existing CSV)
- Scheduled or recurring exports

## Decisions

**Constraints**

- [004 — Customer downloads are served from expiring links](docs/decisions/004-customer-downloads-are-served-from-expiring-links.md) — the finished export file is delivered the same way

**Open**

- Does a long-running export need a new background process, and which runtime runs it? (new process or runtime)

## Starting points

- `app/orders/export_controller.rb` — handles the export request today
- `app/orders/csv_builder.rb` — builds the file row by row
```

### Why This Works

✅ Title is a present-tense claim about the outcome, not a task or a mechanism
✅ Current state leads with the impact (customers can't export, support load), then supports it with
observable facts
✅ Ideal state uses "X does Y" framing and names no mechanism — each bullet is a verifiable fact
✅ Each Ideal state limit (1,000,000 orders) came from the requester
✅ Out of scope lists only the two exclusions the requester stated
✅ Decisions links the one record that binds the work and leaves the background-work question open
instead of picking a job queue
✅ Starting points explain today's behavior, not where the change should go
