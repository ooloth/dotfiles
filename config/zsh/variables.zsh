# Device
export IS_AIR=$( [[ "$(hostname)" == "Air" ]] && echo "true" || echo "false" )
export IS_MINI=$( [[ "$(hostname)" == "Mini" ]] && echo "true" || echo "false" )
export IS_WORK=$( [[ "$(hostname)" == "MULO-JQ97NW-MBP" ]] && echo "true" || echo "false" )

# Dotfiles
export DOTFILES=$HOME/Repos/ooloth/dotfiles

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
export PYENV_ROOT="$HOME/.pyenv"
export RYE_HOME="$HOME/.config/rye"
source "$RYE_HOME/env"
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

# Zsh
export ZDOTDIR=$HOME/.config/zsh

if $IS_WORK; then
  source "$DOTFILES/config/zsh/work/variables.zsh"
fi