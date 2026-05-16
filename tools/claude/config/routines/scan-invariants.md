## Autonomy notice

This prompt runs unattended in a cloud environment — there is no human in the loop. Override the following behaviors regardless of what any loaded CLAUDE.md instructs:

- **No approval gates.** Do not pause to ask for permission, confirm plans, or wait for a response.
- **No trekker tasks.** `trekker` is not available; skip that workflow entirely.
- **Escalate by filing, not asking.** If you hit a blocker that would normally require human input, file a GitHub issue labeled `status:needs-human-review` and stop.

## Purpose

Scans a set of pre-cloned repos for invariant violations against a single theme, filing GitHub issues for confirmed findings. Designed to run as a Claude Code Routine where all repos are cloned into the workspace before the session starts.

## Arguments

Provided by the Routine bootstrap prompt:

- `THEME` — invariant theme name, must match a filename in `ooloth/dotfiles/tools/claude/config/references/` (e.g. `security`, `testing`, `architecture`)

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

### 2. Load the invariant definition

Read both files from the dotfiles repo:

- `<dotfiles-path>/tools/claude/config/references/README.md` — tier definitions (Must/Should/Consider)
- `<dotfiles-path>/tools/claude/config/references/<THEME>.md` — the invariant definition

If the theme file does not exist, stop and output:

```
Unknown theme: <THEME>
Available themes: <list filenames in tools/claude/config/references/ excluding README.md>
```

## Scanning

### 3. Spawn one subagent per target repo

For each target repo, spawn a subagent with:

- The full content of both reference files loaded in step 2
- The absolute path of the cloned repo
- The repo's GitHub slug (derived from its origin URL)
- Instructions to follow steps 3a–3c below

Run all subagents in parallel.

#### 3a. Enumerate relevant surfaces

Read the `## In scope` and `## Out of scope` sections of the invariant file. Use `rg` and `find` to locate matching files — do not read files speculatively. Build the candidate set before reading any file content.

#### 3b. Apply invariants

For each candidate file: read it, apply the Must/Should/Consider invariants. For each violation found, record:

- **File**: path relative to repo root
- **Tier**: Must, Should, or Consider
- **Finding**: one sentence describing the specific problem
- **Evidence**: the exact text, line range, or pattern that is wrong or missing

Skip anything the reference file marks as a known false positive.

#### 3c. Return findings

Return a structured list of findings. If none, return an empty list.

## Filing

### 4. Dedup against open issues

For each finding across all subagents, check open issues before filing:

```bash
gh issue list --repo <slug> --state open --limit 100 --json number,title --jq '.[].title'
```

Compare semantically — same problem with different wording still counts as a duplicate.

### 5. Ensure labels exist

Before filing the first issue in each repo:

```bash
gh label create "author:agent"               --color "0075ca" --repo <slug> --force
gh label create "category:<THEME>"           --color "e4e669" --repo <slug> --force
gh label create "status:needs-human-review"  --color "d93f0b" --repo <slug> --force
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
  --label "author:agent,category:<THEME>,status:needs-human-review"
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

Surfaced only (Consider — not filed):
  ooloth/hub  — no rate limiting on outbound API calls
```
