# Symlinks

How this repo links config files into `$HOME` — conventions for writing
correct `link.bash` scripts.

## Must

**Renamed and deleted symlink sources leave nothing behind.**
When a source moves or disappears, the links pointing at it go with it in
the same change. Broken symlinks don't accumulate in `$HOME`. Creating a
replacement link is not the same as retiring the one it supersedes.

## Should

**New symlinking logic uses the shared `symlink()` helper in
`tools/bash/utils.bash`, not a hand-rolled `ln` call.** A hand-rolled
`ln -s` would still create a working symlink, so this isn't required for
correctness — but the helper's check-mode support (`DOTFILES_CHECK=true`)
and consistent handling of existing or incorrect symlinks are lost
without it.
