
if ! have gcloud; then
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
