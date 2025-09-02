#!/usr/bin/env zsh

source "${DOTFILES}/tools/zsh/utils.zsh"

# Return early if not installed
if ! have gcloud; then
  return 0
fi

export PATH="${HOME}/google-cloud-sdk/bin:$PATH"

# see: https://stackoverflow.com/a/47867652/8802485
# see: https://cloud.google.com/docs/authentication/application-default-credentials
export GOOGLE_APPLICATION_CREDENTIALS="${HOME}/.config/gcloud/application_default_credentials.json"

if is_work; then
  export GOOGLE_CLOUD_PROJECT="eng-infrastructure"
fi

