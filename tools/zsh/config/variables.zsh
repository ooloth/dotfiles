#################
# PREREQUISITES #
#################

source "${DOTFILES}/tools/macos/shell/aliases.zsh" # sets is_air, is_mini, is_work
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

#############
# AUTOMATIC #
#############

# Find all integration.bash files in each tool directory (except @new and @archive)
shell_variables_files=($(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -name "variables.zsh" -print))

for file in "${shell_variables_files[@]}"; do
  printf "Sourcing %s\n" "${file}"
  source "${file}"
done

# source "${DOTFILES}/tools/claude/shell/variables.zsh"
# source "${DOTFILES}/tools/homebrew/shell/variables.zsh"
# source "${DOTFILES}/tools/rust/shell/variables.zsh"

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

if is_work; then
  # NPM
  export NPM_CONFIG_USERCONFIG=${HOME}/.config/npm/.npmrc

  source "${DOTFILES}/tools/zsh/config/work/variables.zsh" 2>/dev/null

  # Configome
  export CONFIGOME_ENV=dev

  # Gcloud
  # see: https://stackoverflow.com/a/47867652/8802485
  # see: https://cloud.google.com/docs/authentication/application-default-credentials
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"

  # Gcloud (update PATH for the Google Cloud SDK)
  # see: https://cloud.google.com/sdk/docs/downloads-interactive
  if [ -f '/Users/michael.uloth/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/michael.uloth/google-cloud-sdk/path.zsh.inc'; fi

  # grey-havens
  export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
  export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1

  # Griphook
  # see: https://github.com/recursionpharma/data-science-onboarding#setting-up-griphook
  source "${HOME}/.griphook/env"

  # Kafka
  # Get the latest version of librdkafka installed by Homebrew
  librdkafka_version=$(ls /opt/homebrew/Cellar/librdkafka | sort -V | tail -n 1)
  export C_INCLUDE_PATH="/opt/homebrew/Cellar/librdkafka/$librdkafka_version/include"
  export LIBRARY_PATH="/opt/homebrew/Cellar/librdkafka/$librdkafka_version/lib"

  # Netskope
  # see: https://github.com/recursionpharma/netskope_dev_tools
  source "$HOME/.config/netskope/env.sh"

  # Roadie
  export ROADIE_BANNER=false
  export ROADIE_USE_UV=true
fi
