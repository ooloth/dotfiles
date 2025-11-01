source "${DOTFILES}/tools/zsh/utils.zsh" # is_work

###########
# ONE-OFF #
###########

alias check="bash ${DOTFILES}/features/check.bash"

alias f='yazi'

alias grep="rg"

alias lint="check" # I forget I refer to this as "check" sometimes

alias mr="sudo shutdown -r now"         # restart macos
alias mini="tailscale ssh michael@mini" # automatically log in using SSH key pair
# alias mini="s michael@mini.local"                       # automatically log in using SSH key pair

alias new="bash ${DOTFILES}/features/new.bash"

alias powerlevel10k="p10k"

alias restart="bash ${DOTFILES}/features/restart.bash"

alias rg="rg --hyperlink-format=kitty" # see: https://sw.kovidgoyal.net/kitty/kittens/hyperlinked_grep/
alias run="bash ${DOTFILES}/features/run.bash"

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
