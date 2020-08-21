source $HOME/.config/.secrets

export PATH="/usr/local/sbin:$PATH"

# Oh my zsh
export ZSH="$HOME/.oh-my-zsh"
export NVM_AUTO_USE=true
ZSH_THEME="dracula"
plugins=(git zsh-nvm zsh-autosuggestions zsh-syntax-highlighting bgnotify)
source $ZSH/oh-my-zsh.sh

# Prompt
SPACESHIP_PACKAGE_SHOW=false
SPACESHIP_EXEC_TIME_SHOW=false
autoload -U promptinit; promptinit
prompt spaceship

# Editor
export EDITOR='nvim'

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# tell fzf to use ripgrep and include hidden files in searches
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git'"

# bat
export BAT_THEME="gruvbox"
# https://github.com/sharkdp/bat#highlighting-theme

# GitHub CLI tab completion
# https://www.youtube.com/watch?v=UNJVqevfg-8
eval "$(gh completion -s zsh)"

# Google Cloud SDK (ecobee)
if [ -f '$HOME/google-cloud-sdk/path.zsh.inc' ]; then . '$HOME/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '$HOME/google-cloud-sdk/completion.zsh.inc' ]; then . '$HOME/google-cloud-sdk/completion.zsh.inc'; fi

# Neovim
alias v='nvim'
alias vim='nvim'

# Jump to common directories
alias cdh='cd $HOME'
alias cds='cd $HOME/Sites'
alias cde='cd $HOME/Sites/ecobee/consumer-website'
alias cdd='cd $HOME/Sites/projects/dotfiles'
alias cdm='cd $HOME/Sites/projects/michaeluloth.com'
alias cdg='cd $HOME/Sites/projects/gatsbytutorials.com'
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

source /Users/Michael/.config/broot/launcher/bash/br
