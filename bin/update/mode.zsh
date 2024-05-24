#!/usr/bin/env zsh

source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🔋 Updating executable permissions"

# Find all ".zsh" files in $DOTFILES/bin and make them executable
fd . "$HOME/Repos/ooloth/dotfiles/bin" -e zsh -X chmod +x

printf "🚀 All scripts are now executable.\n"