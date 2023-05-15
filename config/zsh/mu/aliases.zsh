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

nig() {
  npm install --location=global \
    @githubnext/github-copilot-cli \
    bash-language-server \
    cssmodules-language-server \
    dockerfile-language-server-nodejs \
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

# find all directories two levels below ~/Repos, pass them to fzf and open the selected one in vs code
repo() {
  code "$(fd -t d --max-depth 2 --min-depth 2 . $HOME/Repos | fzf)"
}

alias s="kitty +kitten ssh"                                                          # kitty's ssh kitten

sl() { ln -sfv $1 $2 } # easier symlinking

alias t='tmux a'

u() {
	npm update -g
	brew upgrade && brew update && brew cleanup && brew doctor
	if $IS_WORK_LAPTOP; then
		# TODO: store version in a variable and update it programmatically?
		echo '🚨 Run "brew info librdkafka" and manually update the version in .zshrc if it has changed.'
	fi
}

alias v='vim'
alias vim='nvim'

# [z]sh [t]ime: measure how long new shells take to launch
zt() { for i in $(seq 1 10); do /usr/bin/time zsh -i -c exit; done }
