# CLAUDE.md

This file provides Claude-specific guidance when working with this dotfiles repository.

For general project information, installation instructions, and usage details, see the
[README](./README.md).

## Uphold Project Invariants

Before designing, writing, or editing any code — invoke the `uphold-project-invariants` skill. It
loads this repo's own `docs/invariants/`, `docs/standards/` and accepted `docs/decisions/`. This is
in addition to the global `uphold-standards` skill, not instead of it: that one carries portable
engineering guidance, this one carries what is true only here.

## No Work Facts

This repository is public. No tracked file names anything from work: not the employer, an
organisation, a repository, a project, a colleague or their GitHub handle, a hostname, an account,
a cloud project or dataset ID, a ticket or an internal URL. That covers examples, test fixtures,
comments, commit messages and issue text as much as code. An example uses made-up names, such as
`alice` or `example-repo#123`, never a value copied from a real session.

A value a tool needs on the work laptop lives in a local file that `.gitignore` lists, the way
`tools/agents/config/skills/monitor-prs/team-repos.local` does, and the tracked file describes
only what that local file holds. Some tracked files still name work values. They are known, and
moving them out is tracked separately, so they are not a precedent for adding more.

## Folder Structure

See README.md for the overview. Key points for Claude:

- Each tool lives in `tools/{tool}/`, with its config in `config/` and, where it needs them, a
  `Brewfile`, `install.bash`, `update.bash`, `preflight.bash`, `link.bash`, `uninstall.bash`,
  `shell.zsh` and a `tests/` folder.
  `tools/@new` is the template, `tools/README.md` explains the approach, and `tools/eza/` or
  `tools/logcli/` show a brew formula with no config.
- Workflows that span tools live in `features/{feature}/`, as bash scripts with a `shell.zsh` that
  defines their aliases.
- `u` runs `features/update/tools.bash`. It first runs `features/update/preflight.bash`, which
  checks every tool's `preflight.bash` and stops `u` if one fails. Then it updates the symlinks
  (`features/update/symlinks.bash`) and runs each tool's `update.bash`. The `symlinks` alias
  runs only the symlink step.
- First-time setup on a new Mac is `features/setup/setup.zsh`, which sources the zsh scripts in
  `features/install/zsh/`, several of them under `deprecated/`. A bash replacement is planned in
  #127. The `wip/` folders, such as `features/setup/wip/` and `tools/tmux/wip/`, are drafts that
  #127 reviews and deletes. Nothing runs them, and some no longer work:
  `tools/tmux/wip/install.bash` calls `install_tpm`, which only `tools/tmux/wip/utils.bash` defines.

### Symlink Management

**Important for Git commits**: `~/.claude/` holds symlinks into this repo. `CLAUDE.md`,
`settings.json`, `agents` and `statusline.sh` come from `tools/claude/config/`, and `skills` and
`standards` come from `tools/agents/config/`. To change global Claude settings, edit and commit the
repo copy, such as `tools/claude/config/CLAUDE.md`.

The symlink creation logic is in `features/update/symlinks.bash`, run by
`features/update/tools.bash` and by the `symlinks` alias. `features/setup/setup.zsh` sources the
deprecated `features/install/zsh/deprecated/symlinks.zsh` instead.

### Claude Development Workflow

When making changes to this repository:

1. **Update all relevant README.md files** after making any user-facing changes
1. **Update all relevant project-level CLAUDE.md files** after clarifying any Claude-specific
   workflows

Work in this repository is committed straight to `main`, with no pull request, so the global step
that opens a draft PR and starts its review does not apply here. The review it exists for still
does: after a session's last commit, a fresh session runs `review-code` on that session's commits,
named by hash, before the session hands off.

### Testing and Verification

- The commands that check a change, and how to run what you changed, are in
  [CONTRIBUTING.md](CONTRIBUTING.md). Read it before running anything, and run every check it lists
  before reporting a change as done.
