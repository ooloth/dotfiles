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

# This will:
# 1. Add credentials to your Docker config (~/.docker/config.json)
# 2. Allow Docker to authenticate when pulling images from us-central1-docker.pkg.dev
info "🐳 Configuring Docker to authenticate with gcloud"
gcloud auth configure-docker us-central1-docker.pkg.dev

# gcloud container clusters get-credentials work-cluster --region us-central1 --project work-cluster-85851b24
# gcloud container clusters get-credentials prod-cluster --region us-central1 --project prod-cluster-cc74bd08

debug "🔁 Restarting shell to load gcloud into PATH"
exec -l "${SHELL}"

debug "🔒 Authenticating with gcloud"
# NOTE: running gcloud init is not required: https://stackoverflow.com/questions/42379685/can-i-automate-google-cloud-sdk-gcloud-init-interactive-command
gcloud auth login --update-adc
