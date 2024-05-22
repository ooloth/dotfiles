# Device
export IS_AIR=$( [[ "$(hostname)" == "Air" ]] && echo "true" || echo "false" )
export IS_MINI=$( [[ "$(hostname)" == "Mini" ]] && echo "true" || echo "false" )
export IS_WORK=$( [[ "$(hostname)" == "MULO-JQ97NW-MBP" ]] && echo "true" || echo "false" )

# Dotfiles
export DEBUG_DOTFILES=false
export DOTFILES=$HOME/Repos/ooloth/dotfiles

# Editor
export EDITOR=code

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

# Pyenv
export PYENV_ROOT=$HOME/.pyenv

# Python
# see: https://github.com/recursionpharma/data-science-onboarding#cloning-some-internal-repos
export PYTHONPATH=$HOME
export MYPYPATH=$HOME
# Avoid extra venv at beginning of prompt (see: https://stackoverflow.com/a/72715907/8802485)
export VIRTUAL_ENV_PROMPT=''

# Rust
export CARGO_HOME=$HOME/.config/cargo
export RUSTUP_HOME=$HOME/.config/rustup
source "$CARGO_HOME/env"

# Shell
export SHELL=$(which zsh)

# Starship
export STARSHIP_CONFIG=$HOME/.config/starship/config.toml

# see: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#user-config
export XDG_CONFIG_HOME=$HOME/.config

# Zsh
export ZDOTDIR=$HOME/.config/zsh

########
# PATH #
########

if $IS_WORK; then
  # Gcloud (update PATH for the Google Cloud SDK)
  # see: https://cloud.google.com/sdk/docs/downloads-interactive
  if [ -f '/Users/michael.uloth/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/michael.uloth/google-cloud-sdk/path.zsh.inc'; fi
fi

# Pyenv
# NOTE: do NOT use eval "$(pyenv init -)" or eval "$(pyenv virtualenv-init -)" (they slow the shell down a lot)
# see: https://github.com/pyenv/pyenv?tab=readme-ov-file#set-up-your-shell-environment-for-pyenv
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"

# OpenSSL
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"

# Rust
export PATH="$HOME/.config/cargo/bin:$PATH"

# Homebrew (keep last so will be at front of PATH)
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/local/bin:/opt/local/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:$PATH" # Add Homebrew's executable directory to front of PATH

########
# WORK #
########

if $IS_WORK; then
  # Configome
  # see: https://app.swimm.io/workspaces/ctl2gE0Uy2okwcN3LfOg/repos/Z2l0aHViJTNBJTNBaXBnLW9yY2hlc3RyYXRvciUzQSUzQXJlY3Vyc2lvbnBoYXJtYQ==/branch/trunk/docs/v0jze
  export CONFIGOME_ENV=dev

  # Gcloud
  # see: https://stackoverflow.com/a/47867652/8802485
  # see: https://cloud.google.com/docs/authentication/application-default-credentials
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"

  # grey-havens
  export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
  export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1

  # Kafka
  # Get the latest version of librdkafka installed by Homebrew
  librdkafka_version=$(ls /opt/homebrew/Cellar/librdkafka | sort -V | tail -n 1)
  export C_INCLUDE_PATH="/opt/homebrew/Cellar/librdkafka/$librdkafka_version/include"
  export LIBRARY_PATH="/opt/homebrew/Cellar/librdkafka/$librdkafka_version/lib"

  # Netskope
  # see: https://github.com/recursionpharma/netskope_dev_tools
  source "$HOME/.config/netskope/env.sh"

  # Vault (griphook)
  # see: https://github.com/recursionpharma/data-science-onboarding#setting-up-griphook
  source $HOME/.griphook/env
fi