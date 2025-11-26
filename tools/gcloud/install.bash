#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

debug "⚠️ Must install gcloud manually via https://cloud.google.com/sdk/docs/install#mac"

# TODO: confirm this works smoothly
# See: https://cloud.google.com/sdk/docs/downloads-interactive#silent
info "☁️ Installing gcloud SDK to ${HOME}/google-cloud-sdk"
curl https://sdk.cloud.google.com >install.sh
bash install.sh --disable-prompts
trash install.sh

# See: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin
info "📦 Installing required gcloud components"
gcloud components install gke-gcloud-auth-plugin
gcloud container clusters get-credentials prod-cluster --region us-central1 --project prod-cluster-cc74bd08

debug "🔁 Restarting shell to load gcloud into PATH"
exec -l "${SHELL}"

debug "🔒 Authenticating with gcloud"
# NOTE: running gcloud init is not required: https://stackoverflow.com/questions/42379685/can-i-automate-google-cloud-sdk-gcloud-init-interactive-command
gcloud auth login --update-adc
