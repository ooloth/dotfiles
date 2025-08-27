#!/usr/bin/env zsh
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

# TODO: replace all of these with tool/<tool>/update.bash files
source "${DOTFILES}/features/update/zsh/gcloud.zsh"
source "${DOTFILES}/features/update/zsh/homebrew.zsh"
source "${DOTFILES}/features/update/zsh/npm.zsh"
source "${DOTFILES}/features/update/zsh/neovim.zsh"
