# Symlinks

How this repo links config files into `$HOME` — conventions for writing
correct `link.bash` scripts.

## Must

**Renamed and deleted symlink sources leave nothing behind.**
When a source moves or disappears, the links pointing at it go with it in
the same change. Broken symlinks don't accumulate in `$HOME`. Creating a
replacement link is not the same as retiring the one it supersedes.

`symlinks` (and so `u`) removes broken links only in the directories that
`any_broken_symlink_dirs` and `repo_symlink_dirs` list in
`tools/bash/utils.bash`. A `link.bash` that links into a new directory adds
it to `repo_symlink_dirs`, or `scripts/checks/link-scripts.bash` fails and
names the directory.

**A change to a linked config file is safe from the moment it is saved.**
Files under `tools/*/config/` are symlinked into `$HOME`, so saving one
changes the running machine before any commit, `u` or migration. On another
machine, the change goes live at `git pull`, before `u` runs there. A change
that is only safe once something else has run waits until that has run, or
ships with that step in the same `u`. Removing `allow-scripts` from
`.npmrc` before Claude Code had left npm broke `claude` within three
minutes (#177).

## Should

**New symlinking logic uses the shared `symlink()` helper in
`tools/bash/utils.bash`, not a hand-rolled `ln` call.** A hand-rolled
`ln -s` would still create a working symlink, so this isn't required for
correctness — but the helper's check-mode support (`DOTFILES_CHECK=true`)
and consistent handling of existing or incorrect symlinks are lost
without it. The helper does replace a real file at the target without
copying it first; whether it should is open in
`../questions/should-symlink-refuse-to-replace-a-real-file.md`.
