#!/usr/bin/env zsh
# set -euo pipefail

source "${DOTFILES}/tools/zsh/utils.zsh" # is_work

############
# FEATURES #
############

# Find all shell/aliases.bash files in each feature directory (except @new and @archive)
shell_aliases_in_features=($(find "${DOTFILES}/features" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/aliases.zsh" -print))

for file in "${shell_aliases_in_features[@]}"; do
  source "${file}"
done

#########
# TOOLS #
#########

# Find all shell/aliases.bash files in each tool directory (except @new and @archive and zsh)
shell_aliases_in_tools=($(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/aliases.zsh" -print))

for file in "${shell_aliases_in_tools[@]}"; do
  source "${file}"
done

##########
# MANUAL #
##########

alias cat="bat --paging=never"
source "${DOTFILES}/features/check.zsh"
alias cte="EDITOR=vim crontab -e"
alias ctl="crontab -l"
alias d="lazydocker"
alias da='docker container ls --all --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias db="docker build ."
de() { docker container exec -it $1 sh; }
alias dc="docker compose"
alias dd="dc down --remove-orphans && docker system prune --force"  # stop and remove one or more containers, networks, images, and volumes (or all if no args provided)
alias dl="dc logs --follow --tail=100"                              # see last 100 log lines of one or more services (or all services if no args provided)
alias du="dc up --build --detach --remove-orphans"                  # recreate and start one or more services (or all services if no args provided)
alias dud="dc up --detach"                                          # start one or more services (or all services if no args provided)
diff() { kitten diff "$1" "$2"; }                                   # see: https://sw.kovidgoyal.net/kitty/kittens/diff/

alias f='yazi'

alias g="lazygit"
alias grep="rg"

alias image="kitten icat" # see: https://sw.kovidgoyal.net/kitty/kittens/icat/

alias k="kubectl"
alias kc="k create"
alias kcd="k create deployment"
alias kd="k describe"
alias ke="k expose"
alias kg="k get"
alias kgw="kg -o wide"
alias kgy="kg -o yaml"
alias ka="kg all"
alias kr="k run"
alias ks="k scale"
# Use stern as a replacement for kubectl logs
# Tails a pod regex or "resource/name" and shows logs for any containers that match the regex
# Add -c regex to filter by container name
# see: https://github.com/stern/stern#usage
alias kl="stern"

alias lint="check" # I forget I refer to this as "check" sometimes

alias mr="sudo shutdown -r now"         # restart macos
alias mini="tailscale ssh michael@mini" # automatically log in using SSH key pair
# alias mini="s michael@mini.local"                       # automatically log in using SSH key pair

n() { npm install "$@"; }
source "${DOTFILES}/features/new.zsh"
ng() { "$DOTFILES/features/update/zsh/npm.zsh"; }
# nu() { n && npm-check -u; } -- conflicts with nushell launch command
alias nvm="fnm"

alias powerlevel10k="p10k"

source "${DOTFILES}/features/restart.zsh"

return_or_exit() {
  local code="$1"                            # The exit code to return or exit with
  return "$code" 2>/dev/null || exit "$code" # return if script is sourced to avoid terminating the parent script; exit if run directly
}

alias rg="rg --hyperlink-format=kitty" # see: https://sw.kovidgoyal.net/kitty/kittens/hyperlinked_grep/
alias rm="trash"                       # see: https://github.com/sindresorhus/trash-cli
source "${DOTFILES}/features/run.zsh"

alias s="kitten ssh" # see: https://sw.kovidgoyal.net/kitty/kittens/ssh/
source "${DOTFILES}/features/start.zsh"
source "${DOTFILES}/features/stop.zsh"
source "${DOTFILES}/features/submit.zsh"

t() { tmux attach || exec tmux; }
source "${DOTFILES}/features/test.zsh"
alias transfer="kitten transfer" # see: https://sw.kovidgoyal.net/kitty/kittens/transfer/
alias ts="tailscale"

alias vscode="code"

if is_work; then
  alias bqq="bq query --use_legacy_sql=false --project_id=datalake-prod-ef49c0c9 --format=prettyjson"

  # see: https://recursion.slack.com/archives/CV1G8MHKK/p1752594420668499?thread_ts=1752594134.745739&cid=CV1G8MHKK
  alias db="docker build --secret id=gcp_adc,src=${HOME}/.config/gcloud/application_default_credentials.json ."

  # see: https://stackoverflow.com/a/51563857/8802485
  # see: https://cloud.google.com/docs/authentication/gcloud#gcloud-credentials
  alias gca="gcloud auth login --update-adc && gcloud auth application-default set-quota-project eng-infrastructure"
  gcsa() { gcloud config set account michael.uloth@recursionpharma.com; }
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

  alias pom='griphook pomerium login' # generate a pomerium token that expires in 12 hours (so I can pass it in requests to internal services that require it)

  ru() { uv tool upgrade rxrx-roadie; }
  rl() { ru && uvx roadie lock "$@"; }
  rv() { ru && uvx roadie venv --output .venv "$@"; }
  rlc() { rl --clobber; }
  rvc() { rv --clobber }
fi
