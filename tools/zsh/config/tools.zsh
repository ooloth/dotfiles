# Add tool-specific environment variables, aliases and completions to zsh environment
#
# This file uses a pre-generated manifest to avoid expensive find operations on every shell startup. The manifest
# includes all shell/*.zsh and shell.zsh files in this project is auto-regenerated when stale (i.e. any .zsh files
# are newer than the manifest).
#
# To manually regenerate: source ${DOTFILES}/features/update/zsh/generate-manifest.zsh

MANIFEST="${DOTFILES}/.cache/shell-files-manifest.zsh"

# Check if manifest needs regeneration
if [[ ! -f "${MANIFEST}" ]] || [[ -n $(find "${DOTFILES}/features" "${DOTFILES}/tools" -name "*.zsh" -newer "$MANIFEST" -print -quit) ]]; then
  # Manifest is missing or stale, regenerate it
  source "${DOTFILES}/features/update/zsh/generate-manifest.zsh"
fi

# Source the manifest (contains all shell.zsh files)
source "${MANIFEST}"

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

if is_work; then
  alias bqq="bq query --use_legacy_sql=false --project_id=datalake-prod-ef49c0c9 --format=prettyjson"

  alias pom='griphook pomerium login' # generate a pomerium token that expires in 12 hours (so I can pass it in requests to internal services that require it)

  ru() { uv tool upgrade rxrx-roadie; }
  rl() { ru && uvx roadie lock "$@"; }
  rv() { ru && uvx roadie venv --output .venv "$@"; }
  rlc() { rl --clobber; }
  rvc() { rv --clobber }
fi

