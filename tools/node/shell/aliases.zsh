#!/usr/bin/env zsh

# Global npm dependencies for current node version
alias ng="zsh ${DOTFILES}/tools/node/update.bash" # updated global npm dependencies for current node version
alias ngl="npm -g list"
alias ngo="npm -g outdated"
alias ngu="npm -g uninstall"

alias no="npm i && npm outdated" # check for outdated project dependencies
