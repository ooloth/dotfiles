---
updated: 2026-10-17
update_when: the helper's behaviour changes, or a laptop is found with a real file at a link target
decays: fast
status: open
---

# Should `symlink()` refuse to replace a real file at its target?

## Why it matters

Every `link.bash` but one calls `symlink()` in `tools/bash/utils.bash`, which runs `ln -fsvw`;
`tools/pi/link.bash` runs the same `ln -fsvw` itself. When the target path holds a real file rather
than a link, `ln -f` deletes it and puts the link in its place. Nothing is copied first and nothing
reports the loss. This happens on the first `u` after a tool is added for a config that already
exists on that laptop, and on a new machine where an app wrote its default config before `u` ran. It
also happens after a working link is broken by a tool that saves its config by writing a temporary
file and renaming it over the target: the link becomes a real file holding the tool's additions,
edits to the repo copy stop reaching it, and the next `u` deletes those additions. The content is
gone unless it was already in the repo.

Check mode does not catch it either. With `DOTFILES_CHECK=true`, a real file at the target is
reported as `MISSING`, which reads as "the link was never made" rather than "something else is in
the way".

## What would settle it

A decision on what `symlink()` does when the target is a real file or directory: replace it, refuse
and fail, or move it aside and then link. The cost side needs an audit of each laptop (home and
work) listing every `link.bash` target that is currently a real file, since any of them would
behave differently under a refusing helper.

## Resolves into

A decision record in `../decisions/`. If the helper stops replacing real files, the rule becomes a
Must in `../standards/symlinks.md`, and check mode reports a real file at the target as its own
status rather than `MISSING`.

## Source

Raised on 2026-10-04 by a planning pass for adding Helix as a managed tool, which found that a
laptop's existing `~/.config/helix/config.toml` would be lost on its first `u`.

## Options

- **Replace (current).** The repo is always the source of truth and `u` never stops on a conflict.
  The cost is silent loss of any content that was not already in the repo.
- **Refuse and fail.** `symlink()` leaves the real file alone, prints what is in the way, and
  returns non-zero, so `u` lists the tool as failed. Nothing is lost. The cost is a manual step
  each time: compare the file with the repo copy, then delete or merge it.
- **Move aside, then link.** `symlink()` renames the real file (for example to
  `config.toml.backup-<timestamp>`), links, and prints where the old file went. Nothing is lost and
  `u` keeps going. The cost is backup files that accumulate until someone removes them, and a
  printed line that is easy to miss in a long `u` run.

## Findings

Nothing here is settled until it graduates into a decision record.

- *Sourced:* `symlink()` runs `ln -fsvw "$source_file" "$target_dir"` (`tools/bash/utils.bash`).
  `man ln` on macOS: "`-f` If the target file already exists, then unlink it so that the link may
  occur. (The `-f` option overrides any previous `-i` and `-w` options.)"
- *Measured (2026-10-04, Air):* in a scratch directory, a real `config.toml` containing
  `my real config` was replaced by a link to the repo copy when `symlink()` ran. The original
  content was gone. Before that, the same call in check mode printed
  `❌ MISSING: config.toml → …`.
- *Reasoned:* the exposure covers every `link.bash`, so the decision is about the shared helper
  rather than any one tool.
- *Measured (2026-10-17, Air):* `~/.claude/settings.json` was a real file, last written at the
  same minute the `tmux-assistant-resurrect` tmux plugin was installed. It held the repo copy plus
  that plugin's `SessionStart` and `SessionEnd` hooks and nothing else. The plugin's installer
  writes its hooks to a temporary file and runs `mv` over `~/.claude/settings.json`, which replaces
  a link with a file, and it does so on every load where its hooks are missing. A restored link
  breaks again unless the repo copy carries the hooks or the plugin is gone.
- *Measured (2026-10-17, Air):* with the plugin uninstalled and the link restored, every
  `link.bash` in check mode reports its links `OK` except `codefresh → ~/.local/bin`, which is
  `MISSING` because nothing is at the target. No link target on this laptop is a real file.
- *Not yet measured:* how many link targets are real files on the work laptop.
