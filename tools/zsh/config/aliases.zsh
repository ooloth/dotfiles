source "${DOTFILES}/tools/zsh/utils.zsh" # is_work

###########
# ONE-OFF #
###########

alias check="bash ${DOTFILES}/features/check.bash"
alias lint="check" # I forget I refer to this as "check" sometimes
alias new="bash ${DOTFILES}/features/new.bash"
alias restart="bash ${DOTFILES}/features/restart.bash"
alias run="bash ${DOTFILES}/features/run.bash"
alias start="bash ${DOTFILES}/features/start.bash"
alias stop="bash ${DOTFILES}/features/stop.bash"
alias submit="bash ${DOTFILES}/features/submit.bash"
alias test="bash ${DOTFILES}/features/test.bash"

alias grep="rg"

alias mini="tailscale ssh michael@mini" # automatically log in using SSH key pair
# alias mini="s michael@mini.local"                       # automatically log in using SSH key pair
alias ts="tailscale"

if is_work; then
  alias bqq="bq query --use_legacy_sql=false --project_id=datalake-prod-ef49c0c9 --format=prettyjson"

  alias pom='griphook pomerium login' # generate a pomerium token that expires in 12 hours (so I can pass it in requests to internal services that require it)

  ru() { uv tool upgrade rxrx-roadie; }
  rl() { ru && uvx roadie lock "$@"; }
  rv() { ru && uvx roadie venv --output .venv "$@"; }
  rlc() { rl --clobber; }
  rvc() { rv --clobber }
fi
