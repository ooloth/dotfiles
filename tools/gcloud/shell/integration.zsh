#!/usr/bin/env zsh

source "${DOTFILES}/tools/zsh/utils.zsh"

if [ -f "${HOME}/google-cloud-sdk/completion.zsh.inc" ]; then
  source "${HOME}/google-cloud-sdk/completion.zsh.inc";
fi
