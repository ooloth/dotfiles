alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias c='clear'
alias cat='bat --paging=never'
alias con='cd $HOME/Repos/ooloth/content'
alias dot='cd $HOME/Repos/ooloth/dotfiles'

# see: https://docs.docker.com/engine/reference/commandline/compose_up/
alias d='lazydocker'
alias da='docker ps --all --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dd='docker compose down --remove-orphans'
de() { 'docker compose exec -it' $1 $2; }
dl() { 'docker compose logs --follow --tail=100' $1; }
alias du='docker compose up --detach --remove-orphans'

alias f='vifm'
alias g='lazygit'
alias h='cd $HOME'

# see: https://the.exa.website/docs/command-line-options
# see EXA_* env vars in zsh/mu/variables.zsh
alias ls='eza --all --group-directories-first --classify' # top level dir + files
alias ld='ls --long --no-user --header --grid'            # top level details
alias lt='ls --tree --git-ignore -I .git'                 # file tree (all levels)
alias lt2='lt --level=2'                                  # file tree (2 levels only)
alias lt3='lt --level=3'                                  # file tree (3 levels only)
alias lt4='lt --level=4'                                  # file tree (4 levels only)
alias md='cd $HOME/Repos/ooloth/media'
alias mini="s michael@192.168.2.22"                       # automatically log in using SSH key pair
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
    # bash-language-server \
    # cssmodules-language-server \
    # dockerfile-language-server-nodejs \
    # emmet-ls \
    # neovim \
    npm-check \
    # pug-lint \
    # svelte-language-server \
    tldr \
    # tree-sitter-cli \
    # typescript \
    # vscode-langservers-extracted
}
nk() { npm run types:check; }
nlc() { npm run lint:check; }
nlf() { npm run lint:fix; }
ns() { n && npm run start; }

alias nvm='fnm'
alias oo='cd $HOME/Repos/ooloth'
alias pilots='cd $HOME/Repos/ooloth/download-pilots'
alias R="exec -l $SHELL"
# alias R="source $HOME/.config/zsh/.zshrc"

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
