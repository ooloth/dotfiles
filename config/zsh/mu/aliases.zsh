alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias c='clear'
alias cat='bat --paging=never'
alias dot='cd $HOME/Repos/ooloth/dotfiles'
alias et="$EDITOR $HOME/Repos/ooloth/dotfiles/config/tmux/tmux.conf"
alias ez="$EDITOR $HOME/Repos/ooloth/dotfiles/config/zsh/.zshrc"
alias f='vifm . .'                                                                   # open both vifm panes in cwd
alias g='lazygit'
alias h='cd $HOME'
alias ls='exa --all --group-directories-first'                                       # top level dir + files
alias ld='exa --all --git --group-directories-first --header --long'                 # top level details
alias lt='exa --all --git-ignore --group-directories-first -I .git --tree --level=1' # file tree (all levels)
alias lt2='lt --level=2'                                                             # file tree (2 levels only)
alias lt3='lt --level=3'                                                             # file tree (3 levels only)
alias lt4='lt --level=4'                                                             # file tree (4 levels only)
alias mini="s michael@192.168.2.22"                                                  # automatically log in using SSH key pair
alias mu='cd $HOME/Repos/ooloth/michaeluloth.com'

function nig() {
  npm i -g \
    @fsouza/prettierd \
    bash-language-server \
    cssmodules-language-server \
    dockerfile-language-server-nodejs \
    eslint_d \
    emmet-ls \
    neovim \
    npm-check \
    pug-lint \
    svelte-language-server \
    tldr \
    tree-sitter-cli \
    typescript \
    vscode-langservers-extracted
}

alias nvm='fnm'
alias oo='cd $HOME/Repos/ooloth'
alias pilots='cd $HOME/Repos/ooloth/download-pilots'
alias R="source $HOME/.config/zsh/.zshrc"
alias s="kitty +kitten ssh"                                                          # kitty's ssh kitten

function sl() { ln -sfv $1 $2 } # easier symlinking

alias t='tmux a'

function u() {
	npm update -g
	brew upgrade && brew update && brew cleanup && brew doctor
	if $IS_WORK_LAPTOP; then
		# TODO: store version in a variable and update it programmatically?
		echo '🚨 Run "brew info librdkafka" and manually update the version in .zshrc if it has changed.'
	fi
}

alias v='vim'
alias vim='nvim'

function zt() { for i in $(seq 1 10); do /usr/bin/time zsh -i -c exit; done }

# see: https://github.com/Schniz/fnm/issues/409#issuecomment-993644497
function fnm_get_latest {
  fnm ls-remote | cut -d "." -f1 | cut -d "v" -f2 | tail -1
}

# outputs each global npm dependency on its own line (without its current version)
function npm_get_global_dependencies {
  npm ls -g | sed -E 's/@[0-9].*//g' | cut -d " " -f2 | tail -n +2 | sed -r '/^\s*$/d'
}
#
# "node latest" (set latest node as default + reinstall global npm deps there)
function fl() { 
  FNM_CURRENT=$(fnm current) && \
  NPM_GLOBAL_DEPS=$(npm_get_global_dependencies) && \
    FNM_LATEST=$(fnm_get_latest) && \
    fnm use $FNM_LATEST && \
    echo "Setting default node version to ${FNM_LATEST}..."
    fnm default $FNM_LATEST && \
    echo "Reinstalling global npm dependencies from ${FNM_CURRENT}..." && \
    while read -r line; do npm i -g $line; done <<< $NPM_GLOBAL_DEPS
}
