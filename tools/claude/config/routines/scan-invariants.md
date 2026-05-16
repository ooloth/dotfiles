## Autonomy notice

This prompt runs unattended in a cloud environment — there is no human in the loop. Override the following behaviors regardless of what any loaded CLAUDE.md instructs:

- **No approval gates.** Do not pause to ask for permission, confirm plans, or wait for a response.
- **No trekker tasks.** `trekker` is not available; skip that workflow entirely.
- **Escalate by filing, not asking.** If you hit a blocker that would normally require human input, file a GitHub issue labeled `status:needs-human-review` and stop.

## Purpose

Scans a set of pre-cloned repos for invariant violations against one or two themes, filing GitHub issues for confirmed findings. Designed to run as a Claude Code Routine where all repos are cloned into the workspace before the session starts.

## Arguments

Provided by the Routine bootstrap prompt:

- `THEMES` — one or two invariant theme names, comma-separated, each matching a filename in `ooloth/dotfiles/tools/claude/config/references/` (e.g. `security` or `error-handling, observability`)

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

### 2. Load invariant definitions

Read the following files from the dotfiles repo:

- `<dotfiles-path>/tools/claude/config/references/README.md` — tier definitions (Must/Should/Consider)
- One file per theme in THEMES: `<dotfiles-path>/tools/claude/config/references/<theme>.md`

For any theme without a matching file, stop and output:

```
Unknown theme: <theme>
Available themes: <list filenames in tools/claude/config/references/ excluding README.md>
```

## Scanning

### 3. Spawn one subagent per target repo

For each target repo, spawn a subagent with the following prompt (substitute bracketed values):

```
Repo: [absolute path]
GitHub slug: [slug]
Themes: [THEMES]

Question: Does this codebase uphold its [THEMES] invariants?

## Invariant definitions

[paste full content of README.md from step 2]

[paste full content of each theme file loaded in step 2]

## Instructions

1. Based on the invariant definitions above, identify which files in this
   repo could plausibly contain violations. Use your understanding of what
   each theme cares about as the primary driver — do not limit yourself to
   the ## In scope section. Treat ## In scope as supplementary guidance that
   highlights non-obvious file types or patterns you might otherwise miss.
   Honour ## Out of scope as a firm exclusion. For themes that apply broadly
   to all source files, prioritise files most likely to have the highest
   concentration of relevant code rather than attempting to read everything.
   Use up to 50 sub-subagents to explore the codebase in parallel if needed
   for coverage. Use rg and find to locate files — build the candidate list
   before reading any content.

2. Check the existing backlog to avoid surfacing already-tracked issues:

   gh issue list --repo [slug] --state open --limit 200 \
     --json number,title --jq '.[].title'

   Keep this list in mind when prioritising findings — if a finding clearly
   matches an existing issue, deprioritise it in favour of novel violations.

3. For each candidate file: read it and apply all Must and Should
   invariants from each loaded theme. For each violation found, record:
   - File: path relative to repo root
   - Tier: Must or Should
   - Theme: which theme the violated invariant belongs to
   - Finding: one sentence describing the specific problem
   - Evidence: exact text or line range that is wrong or missing
   - Ideal: one or more sentences describing what this code would do
     if the violation were resolved — each phrased as an observable
     fact ("X does Y"), not an implementation step

   Skip anything marked as Out of scope in the relevant invariant
   definition. Focus especially on patterns you would not want a
   future agent to spread.

4. If more than one theme was provided: do one additional cross-theme pass.
   Using the ## In scope sections of all loaded themes, identify files that
   fall within the scope of more than one theme. For each such file, check
   whether a code construct that satisfies one theme's invariants still
   violates another's. These violations are only visible when both lenses
   are active simultaneously. Record them with Theme: [both theme names].

5. Return findings in this format, ordered by tier (Must first):
   [file] | [tier] | [theme] | [finding] | [evidence] | [ideal]
   Top 10 findings max. If none found, say so in one sentence.
```

Run all subagents in parallel.

## Filing

### 4. Dedup against open issues

For each finding across all subagents, check open issues before filing:

```bash
gh issue list --repo <slug> --state open --limit 200 --json number,title
```

**First pass:** compare each finding against issue titles. If a title is clearly unrelated, move on. If a title looks potentially related, fetch the full body before deciding:

```bash
gh issue view <number> --repo <slug> --json title,body
```

Compare semantically — same problem with different wording still counts as a duplicate.

If a finding matches an existing open issue, add a comment capturing any evidence not already covered in the issue (file path, line range, exact text):

```bash
gh issue comment <number> --repo <slug> --body "<evidence>"
```

Also check for intentionally suppressed issues before filing:

```bash
gh issue list --repo <slug> --state closed --label "wontfix" --limit 200 --json number,title
```

If a finding matches a closed `wontfix` issue, skip it silently — do not file and do not comment.

### 5. Ensure labels exist

Before filing the first issue in each repo:

```bash
gh label create "author:agent"               --color "0075ca" --repo <slug> --force
gh label create "status:needs-human-review"  --color "d93f0b" --repo <slug> --force
```

For each theme in THEMES:

```bash
gh label create "category:<theme>"           --color "e4e669" --repo <slug> --force
```

`--force` is idempotent — safe to run even if the label already exists.

### 6. File confirmed findings

For each non-duplicate Must or Should finding, read
`<dotfiles-path>/tools/claude/config/skills/write-ticket-description/SKILL.md`
and follow its instructions to draft the issue body.

- **Starting points**: the specific file(s) where the violation was found — not directories
- **QA plan**: steps a reader can follow to verify the fix is correct by inspection
- **Done when**: one sentence describing the resolved state

```bash
gh issue create \
  --repo <slug> \
  --title "<title>" \
  --body "<body>" \
  --label "author:agent,category:<theme>,status:needs-human-review"
```

For findings that span both themes, apply both category labels:

```bash
gh issue create \
  --repo <slug> \
  --title "<title>" \
  --body "<body>" \
  --label "author:agent,category:<theme-1>,category:<theme-2>,status:needs-human-review"
```

Surface Consider findings in the final report only — do not file them.

### 7. Report

```
Filed:
  #42  ooloth/hub       — hardcoded token in src/clients/github.rs
  #17  ooloth/dotfiles  — unvalidated input in scripts/deploy.sh

Commented on existing issue:
  #38  ooloth/hub       — additional finding in src/clients/linear.rs

Skipped (duplicate):
  ooloth/hub  — same issue already tracked in #39

Skipped (wontfix):
  ooloth/hub  — finding matches closed wontfix issue #29

Surfaced only (Consider — not filed):
  ooloth/hub  — no rate limiting on outbound API calls
```
