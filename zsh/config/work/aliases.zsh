bp() { cd "$HOME/Repos/recursionpharma/build-pipelines"; }
cauldron() { cd "$HOME/Repos/recursionpharma/cauldron"; }
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
rl() { ru && uvx --python 3.11 roadie lock "$@"; }
# rl() { ru && roadie lock --python 3.11 "$@"; } # NOTE: will use roadie from local venv instead of global roadie
rv() { ru && uv pip install -r pyproject.toml --extra dev "$@"; }
# rv() { ru && uvx roadie venv --output .venv --uv "$@"; }
rlc() { rl --clobber; }
rvc() { rv --reinstall; }
# rvc() { rv --clobber; }

tech() { cd "$HOME/Repos/recursionpharma/tech"; }

zuul() { cd "$HOME/Repos/recursionpharma/zuul"; }
