#!/usr/bin/env zsh

repo="knubie/vim-kitty-navigator"
local_repo="$HOME/Repos/$repo"

# Return if installed
if [ -d "$local_repo" ]; then
  printf "\n📂 vim-kitty-navigator is already installed\n"
  return
fi

# Otherwise, clone and symlink
source "$HOME/Repos/ooloth/dotfiles/config/zsh/utils.zsh"
info "📂 Installing vim-kitty-navigator kitten"

# see: https://github.com/knubie/vim-kitty-navigator?tab=readme-ov-file#kitty
mkdir -p "$local_repo"
git clone "git@github.com:$repo.git" "$local_repo"
ln -sfv "$local_repo/get_layout.py" "$HOME/.config/kitty"
ln -sfv "$local_repo/pass_keys.py" "$HOME/.config/kitty"

printf "\n📦 TODO: install lazy.nvim plugins + reload as needed for first setup?\n"
