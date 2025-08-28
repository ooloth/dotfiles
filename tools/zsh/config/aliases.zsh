#!/usr/bin/env zsh
# set -euo pipefail

# TODO: find all {tool|feature}/shell/aliases.zsh files and source them
source "${DOTFILES}/tools/macos/shell/aliases.zsh"
source "${DOTFILES}/tools/zsh/utils.zsh"
source "${DOTFILES}/features/install/shell/aliases.zsh"
source "${DOTFILES}/features/update/shell/aliases.zsh"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias adv="cd $HOME/Repos/ooloth/advent-of-code"

alias c="clear"
alias cat="bat --paging=never"
alias cd="z"
source "${DOTFILES}/tools/zsh/config/check.zsh"
alias cte="EDITOR=vim crontab -e"
alias ctl="crontab -l"
alias con="cd $HOME/Repos/ooloth/content"
alias conf="cd $HOME/Repos/ooloth/config.nvim"

alias dot="cd $DOTFILES"
alias d="lazydocker"
alias da='docker container ls --all --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dash="cd $HOME/Repos/ooloth/dashboard"
alias db="docker build ."
de() { docker container exec -it $1 sh; }
alias dc="docker compose"
alias dd="dc down --remove-orphans && docker system prune --force"  # stop and remove one or more containers, networks, images, and volumes (or all if no args provided)
alias dl="dc logs --follow --tail=100"                              # see last 100 log lines of one or more services (or all services if no args provided)
alias du="dc up --build --detach --remove-orphans"                  # recreate and start one or more services (or all services if no args provided)
alias dud="dc up --detach"                                          # start one or more services (or all services if no args provided)
diff() { kitten diff "$1" "$2"; }                                   # see: https://sw.kovidgoyal.net/kitty/kittens/diff/

alias env="env | sort"

alias f='yazi'

alias g="lazygit"
alias grep="rg"

alias h="cd $HOME"
alias hub="cd $HOME/Repos/ooloth/hub"

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
# kill process running on given port
kill() { lsof -t -i:"$1" | xargs kill -9; }

alias lint="check" # I forget I refer to this as "check" sometimes
# see: https://github.com/eza-community/eza#command-line-options
# NOTE: see EZA_* env vars in variables.zsh
alias ls="eza --all --group-directories-first --classify" # top level dir + files
alias ld="ls --long --no-user --header"                   # top level details
alias lt="ls --tree --git-ignore -I .git"                 # file tree (all levels)
alias lt2="lt --level=2"                                  # file tree (2 levels only)
alias lt3="lt --level=3"                                  # file tree (3 levels only)
alias lt4="lt --level=4"                                  # file tree (4 levels only)

alias md="cd $HOME/Repos/ooloth/media"
alias mr="sudo shutdown -r now"         # restart macos
alias mini="tailscale ssh michael@mini" # automatically log in using SSH key pair
# alias mini="s michael@mini.local"                       # automatically log in using SSH key pair
alias mu="cd $HOME/Repos/ooloth/michaeluloth.com"

n() { npm install "$@"; }
source "${DOTFILES}/tools/zsh/config/new.zsh"
ng() { "$DOTFILES/features/update/zsh/npm.zsh"; }
# nu() { n && npm-check -u; } -- conflicts with nushell launch command
alias neovim="nvim"
alias nvim="NVIM_APPNAME=nvim-ide nvim"
alias nvm="fnm"

alias oo="cd $HOME/Repos/ooloth"

alias pilots="cd $HOME/Repos/ooloth/download-pilots"
alias powerlevel10k="p10k"

# Keep 'r' as an alias that can be overridden by alias in work/aliases.zsh
# alias r="PYTHONPATH=$HOME/Repos/ooloth/scripts uv run --project $HOME/Repos/ooloth/scripts -m cli"
alias R="source ${HOME}/.zshenv && source ${HOME}/.zshrc" # see https://stackoverflow.com/questions/56284264/recommended-method-for-reloading-zshrc-source-vs-exec
source "${DOTFILES}/tools/zsh/config/restart.zsh"
return_or_exit() {
  local code="$1"                            # The exit code to return or exit with
  return "$code" 2>/dev/null || exit "$code" # return if script is sourced to avoid terminating the parent script; exit if run directly
}
alias rg="rg --hyperlink-format=kitty" # see: https://sw.kovidgoyal.net/kitty/kittens/hyperlinked_grep/
alias rm="trash"                       # see: https://github.com/sindresorhus/trash-cli
source "${DOTFILES}/tools/zsh/config/run.zsh"

alias s="kitten ssh" # see: https://sw.kovidgoyal.net/kitty/kittens/ssh/
alias scraper="cd $HOME/Repos/ooloth/scraper"
sl() {
  local source_file="$1"
  local target_dir="$2"

  mkdir -p "$target_dir"
  printf "🔗 " # inline prefix for the output of the next line
  ln -fsvw "$source_file" "$target_dir";
}
source "${DOTFILES}/tools/zsh/config/start.zsh"
source "${DOTFILES}/tools/zsh/config/stop.zsh"
source "${DOTFILES}/tools/zsh/config/submit.zsh"

t() { tmux attach || exec tmux; }
source "${DOTFILES}/tools/zsh/config/test.zsh"
alias transfer="kitten transfer" # see: https://sw.kovidgoyal.net/kitty/kittens/transfer/
alias ts="tailscale"

v() {
  (have "nvim" && nvim "$@") || (have "vim" && vim "$@") || vi "$@"
}
alias vscode="code"

alias x="exit"

zt() {
  # [z]sh [t]ime: measure how long new shells take to launch
  for i in $(seq 1 10); do
    /usr/bin/time zsh -i -c exit
  done
}

if is_work; then
  alias bp="cd ${HOME}/Repos/recursionpharma/build-pipelines"
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

  alias maf="cd react-app"
  alias pom='griphook pomerium login' # generate a pomerium token that expires in 12 hours (so I can pass it in requests to internal services that require it)

  alias r="cd $HOME/Repos/recursionpharma"
  ru() { uv tool upgrade rxrx-roadie; }
  rl() { ru && uvx roadie lock "$@"; }
  rv() { ru && uvx roadie venv --output .venv "$@"; }
  rlc() { rl --clobber; }
  rvc() { rv --clobber }

  tech() { cd "$HOME/Repos/recursionpharma/tech"; }
fi
