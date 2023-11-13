alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias c='clear'
alias cat='bat --paging=never'
alias con='cd $HOME/Repos/ooloth/content'
alias dot='cd $HOME/Repos/ooloth/dotfiles'

alias d='lazydocker'

# docker container
alias da='docker container ls --all --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
de() { docker container exec -it $1 sh; }

# docker compose
dcb() { docker compose up --build --detach --remove-orphans "$@"; } # recreate and start one or more services (or all services if no args provided)
dcd() { docker compose down --remove-orphans "$@"; }        # stop and remove one or more containers, networks, images, and volumes (or all if no args provided)
dcl() { docker compose logs --follow --tail=100 "$@"; }     # see last 100 log lines of one or more services (or all services if no args provided)
dcu() { docker compose up --detach --remove-orphans "$@"; } # start one or more services (or all services if no args provided)

alias f='vifm'
alias g='lazygit'
alias h='cd $HOME'

# kill process running on given port
k() { lsof -t -i:$1 | xargs kill -9; }

# see: https://the.exa.website/docs/command-line-options
# see EXA_* env vars in zsh/mu/variables.zsh
alias ls='eza --all --group-directories-first --classify' # top level dir + files
alias ld='ls --long --no-user --header --grid'            # top level details
alias lt='ls --tree --git-ignore -I .git'                 # file tree (all levels)
alias lt2='lt --level=2'                                  # file tree (2 levels only)
alias lt3='lt --level=3'                                  # file tree (3 levels only)
alias lt4='lt --level=4'                                  # file tree (4 levels only)
alias md='cd $HOME/Repos/ooloth/media'
alias mini="s michael@mini.local"                         # automatically log in using SSH key pair
alias mu='cd $HOME/Repos/ooloth/michaeluloth.com'

n() { npm install -- $1; }
nb() { n && npm run build; }
nc() { npm run check; }
nd() { n && npm run dev; }
nfc() { npm run format:check; }
nff() { npm run format:fix; }
ng() {
  npm install --location=global \
    @githubnext/github-copilot-cli \
    npm-check \
    tldr \
    # bash-language-server \
    # cssmodules-language-server \
    # dockerfile-language-server-nodejs \
    # emmet-ls \
    # neovim \
    # pug-lint \
    # svelte-language-server \
    # tree-sitter-cli \
    # typescript \
    # vscode-langservers-extracted
}
nk() { npm run types:check; }
nlc() { npm run lint:check; }
nlf() { npm run lint:fix; }
ns() { n && npm run start; }
nu() { n && npm-check -u; }

alias nvm='fnm'
alias oo='cd $HOME/Repos/ooloth'
alias pilots='cd $HOME/Repos/ooloth/download-pilots'
alias r='sudo shutdown -r now' # restart macos
alias R="exec -l $SHELL"
alias s="kitty +kitten ssh" # kitty's ssh kitten

sl() { ln -sfv $1 $2; } # easier symlinking

alias t='tmux a'

u() {
  # update all global npm packages to their latest versions
  # see: https://docs.npmjs.com/cli/v9/commands/npm-update?v=true#updating-globally-installed-packages
	ng

  # update all brew packages to their latest versions
	brew upgrade && brew update && brew cleanup && brew doctor

	if $IS_WORK_LAPTOP; then
		# TODO: store version in a variable and update it programmatically?
		echo '🚨 Run "brew info librdkafka" and manually update the version in .zshrc if it has changed.'

    gcloud components update
	fi
}

alias v='NVIM_APPNAME=nvim-simple nvim'
alias vim='nvim'
alias vl='NVIM_APPNAME=nvim-lazyvim nvim'

# find all directories two levels below ~/Repos, pass them to fzf, and open the selected one in vs code
vs() {
  code "$(fd -t d --max-depth 2 --min-depth 2 . $HOME/Repos | fzf)"
}

vv() {
  # Assumes all configs are in directories named ~/.config/nvim-*
  local config=$(fd --max-depth 1 --glob 'nvim-*' ~/.config | fzf --prompt="Neovim Config > " --height=~50% --layout=reverse --border --exit-0)

  # If I exit fzf without selecting a config, don't open Neovim
  [[ -z $config ]] && echo "No config selected" && return

  # Open Neovim with the selected config
  NVIM_APPNAME=$(basename $config) nvim
}

vvv() {
  # Assumes configs exist in folders named ~/.config/nvim-*
  select config in lazyvim kickstart nvchad astrovim lunarvim
  # select config in simple lazyvim
  do NVIM_APPNAME=nvim-$config nvim; break; done
}

alias x='exit'

# [z]sh [t]ime: measure how long new shells take to launch
zt() { for i in $(seq 1 10); do /usr/bin/time zsh -i -c exit; done }
