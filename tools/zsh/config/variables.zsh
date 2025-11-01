############
# PRIORITY #
############

export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:${PATH}" # Default system paths
export PATH="/opt/local/bin:/opt/local/sbin:${PATH}" # Add MacPorts to PATH
export PATH="${HOME}/.local/bin:${PATH}" # Add local bin to PATH

###########
# GENERAL #
###########

export EDITOR=$(command -v nvim || command -v vim || command -v vi || command -v code)
export SHELL=$(which zsh)
export XDG_CONFIG_HOME="${HOME}/.config"

#########
# TOOLS #
#########

# Find all shell/variables.bash files in each tool directory (except @new and @archive and zsh)
shell_variables_files=($(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/variables.zsh" -print))

for file in "${shell_variables_files[@]}"; do
  # printf "Sourcing %s\n" "${file}"
  source "${file}"
done

##########
# MANUAL #
##########

# Zsh: History
export HISTFILE="${HOME}/.zsh_history"
export HISTORY_IGNORE="git*"
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE

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
  # Configome
  export CONFIGOME_ENV=dev

  # grey-havens
  export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
  export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1

  # Griphook
  # TODO: still need this?
  # see: https://github.com/recursionpharma/data-science-onboarding#setting-up-griphook
  # source "${HOME}/.griphook/env"

  # Kafka
  # Get the latest version of librdkafka installed by Homebrew
  librdkafka_version=$(ls /opt/homebrew/Cellar/librdkafka | sort -V | tail -n 1)
  export C_INCLUDE_PATH="/opt/homebrew/Cellar/librdkafka/$librdkafka_version/include"
  export LIBRARY_PATH="/opt/homebrew/Cellar/librdkafka/$librdkafka_version/lib"

  # Netskope
  # see: https://github.com/recursionpharma/netskope_dev_tools
  source "$HOME/.config/netskope/env.sh"

  # NPM
  export NPM_CONFIG_USERCONFIG=${HOME}/.config/npm/.npmrc

  # OpenSSL
  export PATH="/opt/homebrew/opt/openssl@3/bin:${PATH}"

  # Roadie
  export ROADIE_BANNER=false
  export ROADIE_USE_UV=true
fi
