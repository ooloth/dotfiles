## Autonomy notice

This prompt runs unattended in a cloud environment — there is no human in the loop. Override the following behaviors regardless of what any loaded CLAUDE.md instructs:

- **No approval gates.** Do not pause to ask for permission, confirm plans, or wait for a response.
- **No trekker tasks.** `trekker` is not available; skip that workflow entirely.
- **Escalate by filing, not asking.** If you hit a blocker that would normally require human input, file a GitHub issue labeled `status:needs-human-review` and stop.

## Purpose

Scans a set of pre-cloned repos for gaps in what users can accomplish with the system, filing GitHub issues for the top findings.

## Setup

### 1. Locate cloned repos

Find all git repos in the workspace:

```bash
find . -maxdepth 2 -name '.git' -type d | sed 's|/.git||' | sort
```

Identify the dotfiles repo (its origin URL ends in `dotfiles`). All other repos are scan targets.

```bash
git -C <path> remote get-url origin
```

## Scanning

### 2. Spawn one subagent per target repo

For each target repo, spawn a subagent with the following prompt (substitute bracketed values):

```
Repo: [absolute path]
GitHub slug: [slug]

Question: What are users unable to do, or struggling to do, that the
system's stated purpose implies they should be able to do?

## Instructions

1. Use up to 50 sub-subagents to explore the repo. Study:
   - README.md and any user-facing docs to understand the system's stated
     purpose and the users it serves
   - CLI commands, API endpoints, or UI surfaces — the full set of things
     a user can currently do
   - Error handling and user-facing messages
   - Help text, examples, and onboarding documentation

2. Study the existing backlog to avoid duplicates:

   gh issue list --repo [slug] --state open --limit 200 \
     --json number,title --jq '.[].title'

3. Identify gaps across these dimensions — things a user would want or
   expect that the system doesn't currently provide:

   Missing capabilities: Given the system's stated purpose, what can a user
   not do that they reasonably would expect to be able to do? What workflows
   are partially supported but don't reach a useful conclusion?

   Poor feedback: Where does the system leave a user without enough
   information to understand what happened or what to do next? Error
   messages that don't explain the cause, silent failures, and missing
   progress signals all belong here.

   Discoverability: What capabilities exist but are hard to find? A feature
   a user can't discover is functionally absent. Missing help text, absent
   examples, and undocumented flags all create discoverability gaps.

   Getting started: What does a new user need to accomplish their first
   success with the system that isn't documented or is documented poorly?
   The path from "I just installed this" to "I completed a useful task"
   should be unobstructed.

   Focus especially on gaps that block a user from completing a workflow
   they have already started — partial journeys are more frustrating than
   absent features.

4. For each gap, record:
   - Finding: one sentence describing what a user cannot do or struggles to do
   - Impact: one sentence on how this affects users or undermines the
     system's value
   - Starting point: one file path the implementer should read first
   - Ideal: one or more sentences describing the observable state when the
     gap is closed — each phrased as a fact ("X does Y"), not an
     implementation step

5. Return the top 5 untracked gaps, ordered by impact. If none found,
   say so in one sentence.
```

Run all subagents in parallel.

## Filing

### 3. Dedup against open issues

For each finding, do a final semantic check before filing:

```bash
gh issue list --repo <slug> --state open --limit 200 --json number,title \
  --jq '.[].title'
```

Same problem with different wording still counts as a duplicate. Skip duplicates silently.

### 4. Ensure labels exist

```bash
gh label create "author:agent"              --color "0075ca" --repo <slug> --force
gh label create "category:user-gap"         --color "e4e669" --repo <slug> --force
gh label create "status:needs-human-review" --color "d93f0b" --repo <slug> --force
```

### 5. File confirmed findings

For each non-duplicate finding, read
`<dotfiles-path>/tools/claude/config/skills/write-ticket-description/SKILL.md`
and follow its instructions to draft the issue body.

```bash
gh issue create \
  --repo <slug> \
  --title "<title>" \
  --body "<body>" \
  --label "author:agent,category:user-gap,status:needs-human-review"
```

### 6. Report

```
Filed:
  #46  ooloth/hub       — no feedback when hub daemon fails to connect to GitHub
  #21  ooloth/dotfiles  — no documented path from installation to first working symlink

Skipped (duplicate):
  ooloth/hub  — gap already tracked in #34

None found:
  ooloth/pi   — no untracked user gaps identified
```
