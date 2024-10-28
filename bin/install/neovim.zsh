#!/usr/bin/env zsh

repo="knubie/vim-kitty-navigator"
local_repo="$HOME/Repos/$repo"

if [ -d "$local_repo" ]; then
  printf "\n📂 vim-kitty-navigator is already installed\n"
  source "$DOTFILES/config/zsh/alias.zsh"
  return_or_exit 0
fi

# Otherwise, clone and symlink
source "$DOTFILES/config/zsh/utils.zsh"
info "📂 Installing vim-kitty-navigator kitten"

# see: https://github.com/knubie/vim-kitty-navigator?tab=readme-ov-file#kitty
mkdir -p "$local_repo"
git clone "git@github.com:$repo.git" "$local_repo"
ln -sfv "$local_repo/get_layout.py" "$HOME/.config/kitty"
ln -sfv "$local_repo/pass_keys.py" "$HOME/.config/kitty"

printf "\n📦 TODO: install lazy.nvim plugins + reload as needed for first setup?\n"
