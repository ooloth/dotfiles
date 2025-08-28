#!/usr/bin/env zsh

# See: https://github.com/eza-community/eza#command-line-options
alias ls="eza --all --group-directories-first --classify" # top level dir + files
alias ld="ls --long --no-user --header"                   # top level details
alias lt="ls --tree --git-ignore -I .git"                 # file tree (all levels)
alias lt2="lt --level=2"                                  # file tree (2 levels only)
alias lt3="lt --level=3"                                  # file tree (3 levels only)
alias lt4="lt --level=4"                                  # file tree (4 levels only)
