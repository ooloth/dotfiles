#!/usr/bin/env zsh

source "${DOTFILES}/tools/zsh/utils.zsh"

# TODO: save and source them instead? which is more performant?
# see: https://alexpasmantier.github.io/television/docs/Users/shell-integration#customizing-shell-integration-scripts

# Enables:
#   - ctrl-r = command history
#   - ctrl-t = command smart autocompletion
# See: https://alexpasmantier.github.io/television/docs/Users/shell-integration
if have tv; then
  eval "$(tv init zsh)"
fi

