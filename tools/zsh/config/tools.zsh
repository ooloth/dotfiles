# Add tool-specific environment variables, aliases and completions to zsh environment

############################
# COMPLETE SHELL.ZSH FILES #
############################

# Find all shell.zsh files in each tool directory (except @new and @archive)
shell_files_in_features=($(find "${DOTFILES}/features" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell.zsh" -print))

for file in "${shell_files_in_features[@]}"; do
  source "${file}"
done

# Find all shell.zsh files in each tool directory (except @new and @archive)
shell_files_in_tools=($(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell.zsh" -print))

for file in "${shell_files_in_tools[@]}"; do
  source "${file}"
done

#####################################
# LEGACY: SHELL/VARIABLES.ZSH FILES #
#####################################

# Find all shell/variables.bash files in each tool directory (except @new and @archive and zsh)
shell_variables_files=($(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/variables.zsh" -print))

for file in "${shell_variables_files[@]}"; do
  source "${file}"
done

###################################
# LEGACY: SHELL/ALIASES.ZSH FILES #
###################################

# Find all shell/aliases.bash files in each feature directory (except @new and @archive)
shell_aliases_in_features=($(find "${DOTFILES}/features" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/aliases.zsh" -print))

for file in "${shell_aliases_in_features[@]}"; do
  source "${file}"
done

# Find all shell/aliases.bash files in each tool directory (except @new and @archive and zsh)
shell_aliases_in_tools=($(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/aliases.zsh" -print))

for file in "${shell_aliases_in_tools[@]}"; do
  source "${file}"
done

#######################################
# LEGACY: SHELL/INTEGRATION.ZSH FILES #
#######################################

# Find all shell/integration.bash files in each tool directory (except @new and @archive)
shell_integration_files=($(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/integration.zsh" -print))

for file in "${shell_integration_files[@]}"; do
  source "${file}"
done

###################################
# LEGACY: ONE-OFF VARIABLES SETUP #
###################################

# NPM
export NPM_CONFIG_USERCONFIG=${HOME}/.config/npm/.npmrc

# OpenSSL
if have brew; then
  export PATH="/opt/homebrew/opt/openssl@3/bin:${PATH}"
  export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
  export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"
fi

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
  source "${HOME}/.config/netskope/env.sh"

  # Roadie
  export ROADIE_BANNER=false
  export ROADIE_USE_UV=true
fi

#################################
# LEGACY: ONE-OFF ALIASES SETUP #
#################################

####################################
# LEGACY: ONE-OFF COMPLETION SETUP #
####################################


if have uv; then
  eval "$(uv generate-shell-completion zsh)"
  eval "$(uvx --generate-shell-completion zsh)"
fi

