#!/usr/bin/env zsh

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias c="clear"
alias env="env | sort"

# kill process running on given port
kill() { lsof -t -i:"$1" | xargs kill -9; }

# Keep 'r' as an alias that can be overridden by alias in work/aliases.zsh
# alias r="PYTHONPATH=$HOME/Repos/ooloth/scripts uv run --project $HOME/Repos/ooloth/scripts -m cli"
alias R="source ${HOME}/.zshenv && source ${HOME}/.zshrc" # see https://stackoverflow.com/questions/56284264/recommended-method-for-reloading-zshrc-source-vs-exec

sl() {
  local source_file="$1"
  local target_dir="$2"

  mkdir -p "$target_dir"
  printf "🔗 " # inline prefix for the output of the next line
  ln -fsvw "$source_file" "$target_dir";
}

alias x="exit"

zt() {
  # [z]sh [t]ime: measure how long new shells take to launch
  for i in $(seq 1 10); do
    /usr/bin/time zsh -i -c exit
  done
}

