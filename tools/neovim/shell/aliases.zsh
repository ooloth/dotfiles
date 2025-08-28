#!/usr/bin/env zsh

alias neovim="nvim"
alias nvim="NVIM_APPNAME=nvim-ide nvim"

v() {
  (have "nvim" && nvim "$@") || (have "vim" && vim "$@") || vi "$@"
}
