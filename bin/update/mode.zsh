#!/usr/bin/env zsh

source "$DOTFILES/config/zsh/utils.zsh"

info "🔋 Updating executable permissions"

# Find all ".zsh" files in $DOTFILES/bin and make them executable
fd . "$HOME/Repos/ooloth/dotfiles/bin" -e zsh -X chmod +x

printf "🚀 All dotfiles scripts are executable.\n"
