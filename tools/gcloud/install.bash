#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# TODO: replace with brew cask? - https://formulae.brew.sh/cask/gcloud-cli
# See: https://cloud.google.com/sdk/docs/downloads-interactive#silent
info "☁️ Installing gcloud SDK to ${HOME}/google-cloud-sdk"
curl https://sdk.cloud.google.com > install.sh
bash install.sh --disable-prompts
trash install.sh

# Reload PATH so gcloud is available to the remaining commands in this script
# shellcheck source=/dev/null
source "${HOME}/google-cloud-sdk/path.bash.inc"

# See: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin
info "📦 Installing required gcloud components"
gcloud components install gke-gcloud-auth-plugin
gcloud container clusters get-credentials prod-cluster --region us-central1 --project prod-cluster-cc74bd08

# Adds credentials to ~/.docker/config.json so Docker can pull from us-central1-docker.pkg.dev
info "🐳 Configuring Docker to authenticate with gcloud"
gcloud auth configure-docker us-central1-docker.pkg.dev

# NOTE: gcloud init is not required: https://stackoverflow.com/questions/42379685/can-i-automate-google-cloud-sdk-gcloud-init-interactive-command
info "🔒 Authenticating with gcloud"
gcloud auth login --update-adc
