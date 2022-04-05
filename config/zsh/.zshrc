# Add Homebrew's executable directory to the front of the PATH
export PATH=/usr/local/bin:$PATH

export EDITOR='nvim'

###########
# ALIASES #
###########

# Make clear faster to type
alias c='clear'

# Replace ls with exa
alias ls='exa --all --group-directories-first'                             # top level dir + files
alias ld='exa --all --git --group-directories-first --header --long'       # top level details
alias lt='exa --all --git-ignore --group-directories-first -I .git --tree' # file tree (all levels)
alias lt2='lt --level=2'                                                   # file tree (2 levels only)
alias lt3='lt --level=3'                                                   # file tree (3 levels only)
alias lt4='lt --level=4'                                                   # file tree (4 levels only)

# Jump to common directories
alias cdh='cd $HOME'
alias cdr='cd $HOME/Repos'
alias cdd='cd $HOME/Repos/ooloth/dotfiles'
alias cde='cd $HOME/Repos/ecobee/consumer-website'
alias cdm='cd $HOME/Repos/ooloth/michaeluloth.com'

# Up we go
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# List directory contents after moving
chpwd() ls

# ecobee 
alias y='yarn install'
alias yd='y && yarn develop'
alias yb='y && yarn build'
alias ys='yb && yarn serve'
alias yc='yarn clean'
alias yt='yarn test:dev'
alias ytu='yarn test:update'
ytp() {
   yt --testPathPattern=$1
}

# Replace vim with neovim
alias vim='nvim'
alias v='vim'
alias lvim='$HOME/.local/bin/lvim'

# Replace nvm with fnm
alias nvm='fnm'

# Open both vifm panes in cwd
alias vifm='vifm . .'

##########
# ecobee #
##########

eval "$(direnv hook zsh)"

#######
# fnm #
#######

eval "$(fnm env --use-on-cd)"

##########
# PROMPT #
##########

export STARSHIP_CONFIG=~/.config/starship/config.toml
eval "$(starship init zsh)"

###########
# PLUGINS #
###########

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
