# Symlinks

How this repo links config files into `$HOME` — conventions for writing
correct `link.bash` scripts.

## Should

**New symlinking logic uses the shared `symlink()` helper in
`tools/bash/utils.bash`, not a hand-rolled `ln` call.** A hand-rolled
`ln -s` would still create a working symlink, so this isn't required for
correctness — but the helper's check-mode support (`DOTFILES_CHECK=true`)
and consistent handling of existing or incorrect symlinks are lost
without it.
