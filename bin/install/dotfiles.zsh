#!/usr/bin/env zsh

repo="ooloth/dotfiles"
local_repo="$HOME/Repos/$repo"

if [ -d "$local_repo" ]; then
  printf "\n📂 Dotfiles are already installed. Pulling latest changes.\n"
  cd "$local_repo"
  git pull
  return
fi

# Otherwise, clone via https (will be converted to ssh by install/github.zsh)
printf "📂 Installing dotfiles"
mkdir -p "$local_repo"
git clone "https://github.com/$repo.git" "$local_repo"

