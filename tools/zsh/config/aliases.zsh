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
alias check="bash ${DOTFILES}/features/check.bash"
alias cte="EDITOR=vim crontab -e"
alias ctl="crontab -l"

alias d="lazydocker"
alias da='docker container ls --all --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias db="docker build ."
de() { docker container exec -it "$@" sh; }
dc() { docker compose "$@"; }
dd() { dc down --remove-orphans "$@"; docker system prune; }    # stop and remove one or more containers, networks, images, and volumes (or all if no args provided)
alias dl="dc logs --follow --tail=100"                          # see last 100 log lines of one or more services (or all services if no args provided)
alias du="dc up --build --detach --remove-orphans"              # recreate and start one or more services (or all services if no args provided)
diff() { kitten diff "$1" "$2"; }                               # see: https://sw.kovidgoyal.net/kitty/kittens/diff/

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

alias new="bash ${DOTFILES}/features/new.bash"

alias powerlevel10k="p10k"

alias restart="bash ${DOTFILES}/features/restart.bash"

alias rg="rg --hyperlink-format=kitty" # see: https://sw.kovidgoyal.net/kitty/kittens/hyperlinked_grep/
alias run="bash ${DOTFILES}/features/run.bash"

alias s="kitten ssh" # see: https://sw.kovidgoyal.net/kitty/kittens/ssh/
alias start="bash ${DOTFILES}/features/start.bash"
alias stop="bash ${DOTFILES}/features/stop.bash"
alias submit="bash ${DOTFILES}/features/submit.bash"

t() { tmux attach || exec tmux; }
alias test="bash ${DOTFILES}/features/test.bash"
alias transfer="kitten transfer" # see: https://sw.kovidgoyal.net/kitty/kittens/transfer/
alias ts="tailscale"

alias vscode="code"

if is_work; then
  alias bqq="bq query --use_legacy_sql=false --project_id=datalake-prod-ef49c0c9 --format=prettyjson"

  alias pom='griphook pomerium login' # generate a pomerium token that expires in 12 hours (so I can pass it in requests to internal services that require it)

  ru() { uv tool upgrade rxrx-roadie; }
  rl() { ru && uvx roadie lock "$@"; }
  rv() { ru && uvx roadie venv --output .venv "$@"; }
  rlc() { rl --clobber; }
  rvc() { rv --clobber }
fi
