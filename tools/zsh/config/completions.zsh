#!/usr/bin/env zsh
set -euo pipefail

# Must come before compinit to support rust tab completions
# See: https://rust-lang.github.io/rustup/installation/index.html
fpath+=~/.zfunc

# Initialize zsh completion before invoking tool-specific completions
# See: https://stackoverflow.com/questions/66338988/complete13-command-not-found-compde
autoload -Uz compinit && compinit

