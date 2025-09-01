#!/usr/bin/env zsh

# TODO: move to tools/docker?
# see: https://recursion.slack.com/archives/CV1G8MHKK/p1752594420668499?thread_ts=1752594134.745739&cid=CV1G8MHKK
alias db="docker build --secret id=gcp_adc,src=${HOME}/.config/gcloud/application_default_credentials.json ."

# see: https://stackoverflow.com/a/51563857/8802485
# see: https://cloud.google.com/docs/authentication/gcloud#gcloud-credentials
alias gca="gcloud auth login --update-adc && gcloud auth application-default set-quota-project eng-infrastructure"
# gcsa() { gcloud config set account michael.uloth@recursionpharma.com; }
# gcpe() {
#   gcsa
#   gcloud config set project eng-infrastructure
#   kubectl config use-context gke_eng-infrastructure_us-east1_principal -n phenoapp
# }
# gcpn() {
#   gcsa
#   gcloud config set project rp006-prod-49a893d8
#   kubectl config use-context gke_rp006-prod-49a893d8_us-central1_rp006-prod -n rp006-neuro-phenomap
# }

alias gca="gcloud auth login --update-adc"
