
# If I haven't installed the Google Cloud SDK, skip the rest.
if [ ! -d "${HOME}/google-cloud-sdk/bin" ]; then
  return 0
fi

########################
# ENVIRONMENT VARIABLES #
########################

export PATH="${HOME}/google-cloud-sdk/bin:$PATH"

# see: https://stackoverflow.com/a/47867652/8802485
# see: https://cloud.google.com/docs/authentication/application-default-credentials
export GOOGLE_APPLICATION_CREDENTIALS="${HOME}/.config/gcloud/application_default_credentials.json"

# The project and BigQuery IDs come from private.env (see private.env.example). A new shell names any
# that are unset, so they are exported only when set rather than as empty values.
if is_work; then
  if [[ -n "${PRIVATE_GCLOUD_PROJECT:-}" ]]; then
    export CLOUDSDK_CORE_PROJECT="${PRIVATE_GCLOUD_PROJECT}"
    export GOOGLE_CLOUD_PROJECT="${PRIVATE_GCLOUD_PROJECT}"
  fi

  # BigQuery
  [[ -n "${PRIVATE_BQ_PROJECT:-}" ]] && export DATALAKE="${PRIVATE_BQ_PROJECT}"
  [[ -n "${PRIVATE_BQ_TABLE:-}" ]] && export AGGREGATED_MAPS="${PRIVATE_BQ_TABLE}"
fi

###########
# ALIASES #
###########

# Single quotes, so the project is read when the alias runs, and names the key when it is unset
alias bqq='bq query --use_legacy_sql=false --project_id="${PRIVATE_BQ_PROJECT:?is unset; see private.env.example}" --format=prettyjson'

# see: https://stackoverflow.com/a/51563857/8802485
# see: https://cloud.google.com/docs/authentication/gcloud#gcloud-credentials
alias gca="gcloud auth login michael.uloth@recursion.com --update-adc"
# alias gca="gcloud auth login --update-adc && gcloud auth application-default"

# The external org account is used only through the `external` gcloud configuration. ADC and the
# default configuration stay on the internal account, because uv's package index authenticates with
# ADC and only the internal account can read it.
alias gcat="gcloud auth login michael.uloth@rxrx.tech --no-activate"

###############
# COMPLETIONS #
###############

if [ -f "${HOME}/google-cloud-sdk/completion.zsh.inc" ]; then
  source "${HOME}/google-cloud-sdk/completion.zsh.inc";
fi
