# routines

Workflow prompts invoked by [Claude Code Routines](https://code.claude.com/docs/en/routines) — Anthropic's scheduled cloud automation feature.

## Files

- `scan-invariants.md` — scans pre-cloned repos for a single invariant theme (from `../references/`), filing GitHub issues for confirmed findings. One Routine per theme; scheduled daily or weekly.
- `implement-ready-issues.md` — finds issues labeled `status:ready-for-agent` across configured repos and opens draft PRs for each. Scheduled daily.
- `implement-issue.md` — single-issue implementation workflow. Called as a subprompt by `implement-ready-issues.md`; not run directly by any Routine.

## How a Routine invokes one

Each Routine is configured at [claude.ai/code/routines](https://claude.ai/code/routines) with:

- A bootstrap prompt that reads the relevant file from this repo (e.g. `Read tools/claude/config/routines/scan-invariants.md from ooloth/dotfiles and execute it. Theme: security.`)
- The list of repos to clone — always includes `ooloth/dotfiles` (for the prompt + references) plus the target repos to scan or implement against
- A trigger (scheduled, GitHub event, or API)
