alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

function bu() {
  brew upgrade && brew update && brew cleanup && brew doctor
  if $IS_WORK_LAPTOP; then
    # TODO: store version in a variable and update it programmatically?
    echo '🚨 Run "brew info librdkafka" and manually update the version in .zshrc if it has changed.'
  fi
}

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
alias nvm='fnm'
alias oo='cd $HOME/Repos/ooloth'
alias pilots='cd $HOME/Repos/ooloth/download-pilots'
alias R="source $HOME/.config/zsh/.zshrc"
alias s="kitty +kitten ssh"                                                          # kitty's ssh kitten

function sl() { ln -sfv $1 $2 } # easier symlinking

alias t='tmux a'
alias v='vim'
alias vim='nvim'

# TODO: make these yarn/npm/python agnostic:
alias y='yarn install'
alias yd='y && yarn start:dev'
alias yb='y && yarn build'
alias ys='yb && yarn serve'
alias yc='yarn clean'
alias yt='yarn test:dev'
function ytp() { yt --testPathPattern=$1 }
alias ytu='yarn test:update'


