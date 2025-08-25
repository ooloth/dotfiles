# This file is sourced first. Setting PATH here ensures that it will apply to all zsh scripts, login shells, and interactive shells.
# See: https://news.ycombinator.com/item?id=39508793
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

##########################
# PREREQUISITE VARIABLES #
##########################

export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/tools/macos/shell/variables.zsh" # sets COMPUTER
source "${DOTFILES}/tools/macos/shell/aliases.zsh" # sets is_air, is_mini, is_work
source "${DOTFILES}/tools/zsh/config/path.zsh" # sets PATH

# Editor
EDITOR=$(command -v nvim || command -v vim || command -v vi || command -v code)

# Eza
# see: https://github.com/eza-community/eza/blob/main/man/eza.1.md#environment-variables
# see: https://github.com/eza-community/eza/blob/main/src/options/vars.rs
export EZA_GRID_ROWS=10
export EZA_ICON_SPACING=2
export EZA_STRICT=true
export TIME_STYLE=long-iso

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# k9s
export K9SCONFIG=$HOME/.config/k9s

# Karabiner-Elements
export GOKU_EDN_CONFIG_FILE=$HOME/.config/karabiner/karabiner.edn

# NPM
export NPM_CONFIG_USERCONFIG=$HOME/.config/npm/.npmrc

# OpenSSL
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"

# Powerlevel10k
export POWERLEVEL9K_CONFIG_FILE="${HOME}/.config/powerlevel10k/p10k.zsh"

# Python
export MYPYPATH="$HOME"
# see: https://github.com/recursionpharma/data-science-onboarding#cloning-some-internal-repos
export PYTHONPATH="$HOME"
# Avoid extra venv at beginning of prompt (see: https://stackoverflow.com/a/72715907/8802485)
export VIRTUAL_ENV_PROMPT=''

# Rust
export CARGO_HOME="$HOME/.config/cargo"
export RUSTUP_HOME="$HOME/.config/rustup"
source "$CARGO_HOME/env"

# Shell
export SHELL=$(which zsh)

# Starship
export STARSHIP_CONFIG=$HOME/.config/starship/config.toml

# see: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#user-config
export XDG_CONFIG_HOME=$HOME/.config

if is_work; then
  source "${DOTFILES}/tools/zsh/config/work/variables.zsh" 2>/dev/null
fi
