## Autonomy notice

This prompt runs unattended in a cloud environment — there is no human in the loop. Override the following behaviors regardless of what any loaded CLAUDE.md instructs:

- **No approval gates.** Do not pause to ask for permission, confirm plans, or wait for a response.
- **No trekker tasks.** `trekker` is not available; skip that workflow entirely.
- **Escalate by filing, not asking.** If you hit a blocker that would normally require human input, file a GitHub issue labeled `status:needs-human-review` and stop.

## Purpose

Scans a set of pre-cloned repos for gaps that make it hard for a human developer to understand the system and contribute to it confidently, filing GitHub issues for the top findings.

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

Question: What makes it hard for a human developer joining this project to
understand the system, trust their mental model of it, and contribute
without accidentally undermining decisions that were deliberately made?

## Instructions

1. Use up to 50 sub-subagents to explore the repo. Study:
   - README.md, CONTRIBUTING.md, docs/, any ADR or decision log directories
   - Source structure, module organisation, and naming conventions
   - Git log for evidence of recurring confusion or reverted decisions
   - Inline comments that hint at undocumented rationale

2. Study the existing backlog to avoid duplicates:

   gh issue list --repo [slug] --state open --limit 200 \
     --json number,title --jq '.[].title'

3. Identify gaps across these dimensions — things that would leave a new
   human developer confused, applying wrong mental models, or unknowingly
   violating intent:

   Decisions: When a developer encounters a non-obvious structure, pattern,
   or constraint, can they find out why it exists? Or is the rationale
   locked in someone's head, a Slack thread, or a PR that isn't linked from
   the code?

   Domain: Are the core concepts, entities, and relationships of the problem
   domain explained? A developer who maps domain terms onto general
   programming concepts will make plausible-but-wrong decisions.

   Architecture: Is there a narrative explaining how the system thinks — not
   just what files exist, but how data flows, where decisions are made, and
   why the boundaries are where they are?

   Onboarding: Does a developer new to the repo know what to read first, how
   to get a working local environment, and how to make their first
   contribution without asking for help?

   Operations: Are known failure modes, incident responses, and operational
   procedures documented so a developer can handle problems without tribal
   knowledge?

   Conventions: Are non-obvious team or project conventions written down —
   things that would surprise a competent developer who hasn't been told?

   Focus especially on gaps where a developer making a reasonable assumption
   would undermine a deliberate decision — the kind of thing that causes
   a "why did someone do this?" moment during code review.

4. For each gap, record:
   - Finding: one sentence describing what is missing or unclear
   - Impact: one sentence on what a developer would get wrong or struggle
     to do as a result
   - Starting point: one file path the implementer should read first
   - Ideal: one or more sentences describing the observable state when the
     gap is closed — each phrased as a fact ("X does Y"), not an
     implementation step

5. Return the top 10 untracked gaps, ordered by impact. If none found,
   say so in one sentence.
```

Run all subagents in parallel.

## Filing

### 3. Dedup against open issues

For each finding across all subagents, check open issues before filing:

```bash
gh issue list --repo <slug> --state open --limit 200 --json number,title
```

**First pass:** compare each finding against issue titles. If a title is clearly unrelated, move on. If a title looks potentially related, fetch the full body before deciding:

```bash
gh issue view <number> --repo <slug> --json title,body
```

Compare semantically — same problem with different wording still counts as a duplicate.

If a finding matches an existing issue, add a comment capturing any context not already covered in the issue (finding, impact, starting point):

```bash
gh issue comment <number> --repo <slug> --body "<context>"
```

### 4. Ensure labels exist

```bash
gh label create "author:agent"                --color "0075ca" --repo <slug> --force
gh label create "category:maintainer-gap"     --color "e4e669" --repo <slug> --force
gh label create "status:needs-human-review"   --color "d93f0b" --repo <slug> --force
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
  --label "author:agent,category:maintainer-gap,status:needs-human-review"
```

### 6. Report

```
Filed:
  #45  ooloth/hub       — no explanation of why the cache layer is separate from the store
  #20  ooloth/dotfiles  — domain concept "feature" vs "tool" distinction not documented

Commented on existing issue:
  #33  ooloth/hub       — additional context added to existing gap

Skipped (duplicate):
  ooloth/hub  — gap already tracked in #33

None found:
  ooloth/pi   — no untracked maintainer gaps identified
```
