# This file is sourced first. Setting PATH here ensures that it will apply to all zsh scripts, login shells, and interactive shells.
# See: https://news.ycombinator.com/item?id=39508793
# See: https://zsh.sourceforge.io/Doc/Release/Files.html
source "$HOME/Repos/ooloth/dotfiles/config/zsh/path.zsh"

# TODO: use set_machine_variables instead?
# Device
export HOSTNAME=$(networksetup -getcomputername)

# TODO: use set_machine_variables instead?
# When referenced in "if" statements, will execute the true/false unix commands that return 0 or 1
# When read directly, will contain "true" or "false" strings
export IS_AIR=false
export IS_MINI=false
export IS_WORK=false

[[ "$HOSTNAME" == "Air" ]] && IS_AIR=true
[[ "$HOSTNAME" == "Mini" ]] && IS_MINI=true
[[ "$HOSTNAME" == "7385-Y3FH97X-MAC" || "$HOSTNAME" == "MULO-JQ97NW-MBP" ]] && IS_WORK=true

# Claude
# See: https://docs.anthropic.com/en/docs/claude-code/settings#environment-variables
# See: https://docs.anthropic.com/en/docs/about-claude/models/overview#model-names
# NOTE: negating IS_WORK always results in true, even if IS_WORK is true, so we avoid negation here
if $IS_WORK; then
else
  export ANTHROPIC_MODEL="claude-sonnet-4-20250514"
fi

# Dotfiles
export DOTFILES=$HOME/Repos/ooloth/dotfiles

source "$DOTFILES/config/zsh/aliases.zsh"
source "$DOTFILES/config/zsh/utils.zsh"

# Editor
editors_in_desc_order_of_preference=("code" "nvim" "vim" "vi")
for editor in "${editors_in_desc_order_of_preference[@]}"; do
  if have "$editor"; then
    export EDITOR="$editor"
    break
  fi
done

# Eza
# see: https://github.com/eza-community/eza/blob/main/man/eza.1.md#environment-variables
# see: https://github.com/eza-community/eza/blob/main/src/options/vars.rs
export EZA_GRID_ROWS=10
export EZA_ICON_SPACING=2
export EZA_STRICT=true
export TIME_STYLE=long-iso

# Homebrew
export HOMEBREW_BUNDLE_FILE="$DOTFILES/macos/Brewfile"
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

# Python
export MYPYPATH="$HOME"
# see: https://github.com/recursionpharma/data-science-onboarding#cloning-some-internal-repos
export PYTHONPATH="$HOME"
# Avoid extra venv at beginning of prompt (see: https://stackoverflow.com/a/72715907/8802485)
export VIRTUAL_ENV_PROMPT=''

if $IS_WORK; then
  export PYENV_ROOT="$HOME/.pyenv"
fi

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

# Zsh
export ZDOTDIR=$HOME/.config/zsh

if $IS_WORK; then
  source "$DOTFILES/config/zsh/work/variables.zsh" 2>/dev/null
fi
