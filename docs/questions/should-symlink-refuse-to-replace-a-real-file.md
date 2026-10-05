---
updated: 2026-10-04
update_when: the helper's behaviour changes, or a laptop is found with a real file at a link target
decays: fast
status: open
---

# Should `symlink()` refuse to replace a real file at its target?

## Why it matters

Every `link.bash` calls `symlink()` in `tools/bash/utils.bash`, which runs `ln -fsvw`. When the
target path holds a real file rather than a link, `ln -f` deletes it and puts the link in its
place. Nothing is copied first and nothing reports the loss. This happens on the first `u` after a
tool is added for a config that already exists on that laptop, and on a new machine where an app
wrote its default config before `u` ran. The content is gone unless it was already in the repo.

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
- *Not yet measured:* how many link targets are real files on each laptop today.
