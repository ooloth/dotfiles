#!/usr/bin/env zsh

source "$DOTFILES/zsh/config/utils.zsh"

info "🐍 Updating uv and its tools..."

uv self upgrade
uv tool upgrade --all

printf "\n🎉 All uv tools are up to date\n"
