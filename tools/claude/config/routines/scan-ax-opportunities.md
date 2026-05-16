## Autonomy notice

This prompt runs unattended in a cloud environment — there is no human in the loop. Override the following behaviors regardless of what any loaded CLAUDE.md instructs:

- **No approval gates.** Do not pause to ask for permission, confirm plans, or wait for a response.
- **No trekker tasks.** `trekker` is not available; skip that workflow entirely.
- **Escalate by filing, not asking.** If you hit a blocker that would normally require human input, file a GitHub issue labeled `status:needs-human-review` and stop.

## Purpose

Scans a set of pre-cloned repos for gaps that make it hard for an AI agent to contribute effectively, filing GitHub issues for the top findings.

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

Question: What makes it hard for an AI agent to contribute effectively to
this repo — to understand the system, make correct decisions, and validate
its own work?

## Instructions

1. Use up to 50 sub-subagents to explore the repo. Study:
   - CLAUDE.md, AGENTS.md, README.md, docs/, .claude/, .agents/
   - CI config, Makefile, Justfile, or equivalent
   - Source structure and any existing conventions documentation

2. Study the existing backlog to avoid duplicates:

   gh issue list --repo [slug] --state open --limit 200 \
     --json number,title --jq '.[].title'

3. Identify gaps across these dimensions — things that would leave an agent
   confused, making wrong decisions, or unable to verify its own work:

   Context: Can an agent dropped into this repo for the first time understand
   what the system does, what problem it solves, and what domain concepts it
   operates on? What would it misunderstand or have to guess?

   Commands: Are the exact commands to run tests, linting, type checking,
   and the system itself documented unambiguously? Would an agent know what
   to run to verify its changes without reading source code?

   Constraints: Are the things an agent must not do stated explicitly —
   files not to touch, patterns not to introduce, decisions already made
   that must not be revisited? Or would an agent have to infer these from
   conventions and risk getting them wrong?

   Feedback: When an agent's changes break something, does the harness
   surface the failure automatically in the same session? Or would the
   agent finish a session believing it succeeded while leaving the repo
   in a broken state?

   Validation: Can the agent invoke the running system and read its signals
   (logs, traces, output) to confirm its changes behaved correctly at
   runtime — not only that tests passed? Are those signals documented and
   discoverable?

   Navigation: Does the agent know where to look for a given type of change?
   Is it clear which files are entry points, which are shared utilities,
   and which should not be modified directly?

   Focus especially on gaps that compound — where an agent missing context
   in one session would make a plausible-but-wrong decision that future
   agents would then build on.

4. For each gap, record:
   - Finding: one sentence describing what is missing or unclear
   - Impact: one sentence on what an agent would get wrong or be unable to
     do as a result
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

If a finding matches an existing open issue, add a comment capturing any context not already covered in the issue (finding, impact, starting point):

```bash
gh issue comment <number> --repo <slug> --body "<context>"
```

Also check for intentionally suppressed issues before filing:

```bash
gh issue list --repo <slug> --state closed --label "wontfix" --limit 200 --json number,title
```

If a finding matches a closed `wontfix` issue, skip it silently — do not file and do not comment.

### 4. Ensure labels exist

```bash
gh label create "author:agent"              --color "0075ca" --repo <slug> --force
gh label create "category:agent-gap"        --color "e4e669" --repo <slug> --force
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
  --label "author:agent,category:agent-gap,status:needs-human-review"
```

### 6. Report

```
Filed:
  #44  ooloth/hub       — no documented command to run the system locally
  #19  ooloth/dotfiles  — constraints on which files agents may edit are unstated

Commented on existing issue:
  #32  ooloth/hub       — additional context added to existing gap

Skipped (duplicate):
  ooloth/hub  — gap already tracked in #32

Skipped (wontfix):
  ooloth/hub  — finding matches closed wontfix issue #29

None found:
  ooloth/pi   — no untracked agent gaps identified
```
