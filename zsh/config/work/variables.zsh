
# Claude Code
# See: https://docs.google.com/document/d/1jaU6-4AyCo3Mn5OoIPz6zOvwEy6i6MilyPG2J7GOjOA/edit?tab=t.0
export ANTHROPIC_VERTEX_PROJECT_ID=vertexai-sandbox-e8a925d0
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=us-east5
export DISABLE_PROMPT_CACHING=1

# Configome
# see: https://app.swimm.io/workspaces/ctl2gE0Uy2okwcN3LfOg/repos/Z2l0aHViJTNBJTNBaXBnLW9yY2hlc3RyYXRvciUzQSUzQXJlY3Vyc2lvbnBoYXJtYQ==/branch/trunk/docs/v0jze
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

# Vault (griphook)
# see: https://github.com/recursionpharma/data-science-onboarding#setting-up-griphook
source $HOME/.griphook/env
