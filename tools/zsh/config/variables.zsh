# This file is sourced first. Setting PATH here ensures that it will apply to all zsh scripts, login shells, and interactive shells.
# See: https://news.ycombinator.com/item?id=39508793
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

#################
# PREREQUISITES #
#################

source "${DOTFILES}/tools/macos/shell/variables.zsh" # sets COMPUTER
source "${DOTFILES}/tools/zsh/config/path.zsh" # sets PATH

###########
# GENERAL #
###########

export EDITOR=$(command -v nvim || command -v vim || command -v vi || command -v code)
export SHELL=$(which zsh)
export XDG_CONFIG_HOME="${HOME}/.config"

#########
# TOOLS #
#########

# TODO: make dynamic

source "${DOTFILES}/tools/homebrew/shell/variables.zsh"
source "${DOTFILES}/tools/rust/shell/variables.zsh"

# Zsh: History
export HISTFILE="${HOME}/.zsh_history"
export HISTORY_IGNORE="git*"
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE

# Eza
# see: https://github.com/eza-community/eza/blob/main/man/eza.1.md#environment-variables
# see: https://github.com/eza-community/eza/blob/main/src/options/vars.rs
export EZA_GRID_ROWS=10
export EZA_ICON_SPACING=2
export EZA_STRICT=true
export TIME_STYLE=long-iso

# k9s
export K9SCONFIG=$HOME/.config/k9s

# NPM
export NPM_CONFIG_USERCONFIG=$HOME/.config/npm/.npmrc

# OpenSSL
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"

# Powerlevel10k
export POWERLEVEL9K_CONFIG_FILE="${HOME}/.config/powerlevel10k/p10k.zsh"

# Python
export MYPYPATH="${HOME}"
export PYTHONPATH="${HOME}"
export VIRTUAL_ENV_PROMPT='' # avoid extra (venv) prompt prefix

# Rust
export CARGO_HOME="$HOME/.config/cargo"
export RUSTUP_HOME="$HOME/.config/rustup"
source "$CARGO_HOME/env"

if is_work; then
  source "${DOTFILES}/tools/zsh/config/work/variables.zsh" 2>/dev/null
fi
