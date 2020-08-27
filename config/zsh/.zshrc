# source $HOME/.secrets
export PATH="/usr/local/sbin:$PATH"
export EDITOR='nvim'

KEYTIMEOUT=1 # Faster ESC response in vi mode

###########
# ALIASES #
###########

# Point tmux to config file
alias tmux='tmux -f $HOME/.config/tmux/tmux.conf'

# Replace vim with neovim
alias vim='nvim'
alias v='vim'

# Replace nvm with fnm
alias nvm='fnm'

# Open both vifm panes in cwd
alias vifm='vifm . .'

# Make clear faster to type
alias c='clear'

# Replace ls with exa
alias ls='exa --all --group-directories-first'                             # top level dir + files
alias lsa='ls --git-ignore -I .git --recurse'                              # nested dirs + files
alias ld='exa --all --git --group-directories-first --header --long'       # top level details
alias lda='ld --git-ignore -I .git --recurse'                              # nested details
alias lt='exa --all --git-ignore --group-directories-first -I .git --tree' # file tree (all levels)
alias lt2='lt --level=2'                                                   # file tree (2 levels)
alias lt3='lt --level=3'                                                   # file tree (3 levels)
alias lt4='lt --level=4'                                                   # file tree (4 levels)

# List directory contents after moving
chpwd() ls

# Up we go
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Jump to common directories
alias cdh='cd $HOME'
alias cds='cd $HOME/Repos'
alias cde='cd $HOME/Repos/ecobee/consumer-website'
alias cdd='cd $HOME/Repos/ooloth/dotfiles'
alias cdm='cd $HOME/Repos/ooloth/michaeluloth.com'
alias cdg='cd $HOME/Repos/ooloth/gatsbytutorials.com'
alias cdn='ssh ooloth@192.168.0.104'

# Common ecobee commands
alias yd='yarn install && yarn develop'
alias jw='$(npm bin)/jest --watch' # tests of uncommitted changes
alias jwa='$(npm bin)/jest --watchAll' # all tests
jwp() {
   $(npm bin)/jest --watch --testPathPattern=$1 # tests matching pattern
}
alias gp='git push --no-verify'
alias yb='yarn build'
alias ys='yarn storybook'

# Speed test
alias speed='speedtest-cli'

# fnm
eval "$(fnm env --multi --use-on-cd)"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# tell fzf to use ripgrep and include hidden files in searches
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git'"

# bat (https://github.com/sharkdp/bat#highlighting-theme)
export BAT_THEME="gruvbox"

# GitHub CLI tab completion (https://www.youtube.com/watch?v=UNJVqevfg-8)
eval "$(gh completion -s zsh)"

# Google Cloud SDK (ecobee)
if [ -f '$HOME/google-cloud-sdk/path.zsh.inc' ]; then . '$HOME/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '$HOME/google-cloud-sdk/completion.zsh.inc' ]; then . '$HOME/google-cloud-sdk/completion.zsh.inc'; fi

# Oh my zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="spaceship"

SPACESHIP_EXEC_TIME_SHOW=false
SPACESHIP_GIT_SYMBOL=''
SPACESHIP_PACKAGE_SHOW=false
SPACESHIP_PROMPT_ORDER=(user dir host git node vi_mode line_sep jobs char)
SPACESHIP_VI_MODE_PREFIX='in '
SPACESHIP_VI_MODE_SHOW=true

plugins=(git vi-mode) # exclude brew-installed plugins
source $ZSH/oh-my-zsh.sh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
