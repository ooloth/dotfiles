#!/usr/bin/env zsh

source "${DOTFILES}/tools/zsh/utils.zsh"

# See: https://github.com/Schniz/fnm/blob/master/docs/configuration.md
if have fnm; then
  eval "$(fnm env --use-on-cd --shell zsh --corepack-enabled --log-level=error)"
fi
