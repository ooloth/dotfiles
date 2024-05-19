# Set up all env vars in .zshenv except PATH
# see: https://apple.stackexchange.com/questions/432226/homebrew-path-set-in-zshenv-is-overridden

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

# History
# TODO: customize HISTORY behavior (validate ideas below + use with fzf?)
# FIXME: this isn't taking effect:
export HISTSIZE=10000
export HISTCONTROL=ignoreboth:erasedups
export HISTORY_IGNORE="git*"
export SAVEHIST=10000

# Host
# NOTE: HOSTNAME set on startup by ~/Library/LaunchAgents/kitty.environment.plist
export IS_WORK_LAPTOP=$( [[ -d "$HOME/Repos/recursionpharma" ]] && echo "true" || echo "false" )

# k9s
export K9SCONFIG=$HOME/.config/k9s

# Karabiner-Elements
export GOKU_EDN_CONFIG_FILE=$HOME/.config/karabiner/karabiner.edn

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
. "$CARGO_HOME/env"

# Shell
export SHELL=$(which zsh)

# Starship
export STARSHIP_CONFIG=$HOME/.config/starship/config.toml

# see: https://stackoverflow.com/a/4332530/8802485
export TEXT_BLACK=$(tput setaf 0)
export TEXT_RED=$(tput setaf 1)
export TEXT_GREEN=$(tput setaf 2)
export TEXT_YELLOW=$(tput setaf 3)
export TEXT_BLUE=$(tput setaf 4)
export TEXT_MAGENTA=$(tput setaf 5)
export TEXT_CYAN=$(tput setaf 6)
export TEXT_WHITE=$(tput setaf 7)
export TEXT_BRIGHT=$(tput bold)
export TEXT_NORMAL=$(tput sgr0)
export TEXT_BLINK=$(tput blink)
export TEXT_REVERSE=$(tput smso)
export TEXT_UNDERLINE=$(tput smul)

# see: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#user-config
export XDG_CONFIG_HOME=$HOME/.config

# Zsh
export ZDOTDIR=$HOME/.config/zsh

# Work
if $IS_WORK_LAPTOP; then
  # Configome
  # see: https://app.swimm.io/workspaces/ctl2gE0Uy2okwcN3LfOg/repos/Z2l0aHViJTNBJTNBaXBnLW9yY2hlc3RyYXRvciUzQSUzQXJlY3Vyc2lvbnBoYXJtYQ==/branch/trunk/docs/v0jze
  export CONFIGOME_ENV=dev

  # kafka
  # Get the latest version of librdkafka installed by Homebrew
  librdkafka_version=$(ls /opt/homebrew/Cellar/librdkafka | sort -V | tail -n 1)
  export C_INCLUDE_PATH="/opt/homebrew/Cellar/librdkafka/$librdkafka_version/include"
  export LIBRARY_PATH="/opt/homebrew/Cellar/librdkafka/$librdkafka_version/lib"

  # Gcloud
  # see: https://stackoverflow.com/a/47867652/8802485
  # see: https://cloud.google.com/docs/authentication/application-default-credentials
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"

  # grey-havens
  export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
  export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
fi