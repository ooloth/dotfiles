#!/usr/bin/env zsh

source "$DOTFILES/tools/zsh/utils.zsh"

info "🐍 Updating uv and its tools..."

uv self update
uv tool upgrade --all

printf "\n🎉 All uv tools are up to date\n"
