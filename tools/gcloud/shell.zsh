
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

if is_work; then

  export CLOUDSDK_CORE_PROJECT="work-cluster-85851b24"
  # export CLOUDSDK_CORE_PROJECT="prod-cluster-cc74bd08"
  export GOOGLE_CLOUD_PROJECT="eng-infrastructure"
fi

###########
# ALIASES #
###########

# see: https://stackoverflow.com/a/51563857/8802485
# see: https://cloud.google.com/docs/authentication/gcloud#gcloud-credentials
alias gca="gcloud auth login --update-adc && gcloud auth application-default set-quota-project eng-infrastructure"
# alias gca="gcloud auth login --update-adc"

###############
# COMPLETIONS #
###############

if [ -f "${HOME}/google-cloud-sdk/completion.zsh.inc" ]; then
  source "${HOME}/google-cloud-sdk/completion.zsh.inc";
fi
