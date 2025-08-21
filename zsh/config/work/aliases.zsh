alias bp ="cd ${HOME}/Repos/recursionpharma/build-pipelines"

# see: https://recursion.slack.com/archives/CV1G8MHKK/p1752594420668499?thread_ts=1752594134.745739&cid=CV1G8MHKK
alias db="docker build --secret id=gcp_adc,src=${HOME}/.config/gcloud/application_default_credentials.json ."

eo() { cd "$HOME/Repos/recursionpharma/eng-onboarding"; }
# see: https://stackoverflow.com/a/51563857/8802485
# see: https://cloud.google.com/docs/authentication/gcloud#gcloud-credentials
gca() { gcloud auth login --update-adc && gcloud auth application-default set-quota-project eng-infrastructure; }
gci() { gcloud init; }
gcsa() { gcloud config set account michael.uloth@recursion.com; }
gcpe() {
  gcsa
  gcloud config set project eng-infrastructure
  kubectl config use-context gke_eng-infrastructure_us-east1_principal -n phenoapp
}
gcpn() {
  gcsa
  gcloud config set project rp006-prod-49a893d8
  kubectl config use-context gke_rp006-prod-49a893d8_us-central1_rp006-prod -n rp006-neuro-phenomap
}
lowe() { cd "$HOME/Repos/recursionpharma/bc-lowe"; }
mp() { cd "$HOME/Repos/recursionpharma/mapapp-public"; }

pa() { cd "$HOME/Repos/recursionpharma/dash-phenoapp-v2"; }
paf() { cd "$HOME/Repos/recursionpharma/dash-phenoapp-v2/react-app"; }
alias pom='griphook pomerium login' # generate a pomerium token that expires in 12 hours (so I can pass it in requests to internal services that require it)
pr() { cd "$HOME/Repos/recursionpharma/phenoreader"; }
psa() { cd "$HOME/Repos/recursionpharma/phenoservice-api"; }
psc() { cd "$HOME/Repos/recursionpharma/phenoservice-consumer"; }

alias r="cd $HOME/Repos/recursionpharma"
ru() { uv tool upgrade rxrx-roadie; } # see: https://pip.pypa.io/en/stable/cli/pip_install/#options
rl() { ru && uvx roadie lock "$@"; } # optionally "rl -c" etc
rv() { ru && uvx roadie venv --output .venv "$@"; }
rlc() { rl --clobber; }
rvc() { rv --clobber }

tech() { cd "$HOME/Repos/recursionpharma/tech"; }

zuul() { cd "$HOME/Repos/recursionpharma/zuul"; }
