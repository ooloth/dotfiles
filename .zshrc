# Oh my zsh
export ZSH="/Users/Michael/.oh-my-zsh"
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
export EDITOR='vim'

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# tell fzf to use ripgrep and include hidden files in searches
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git'"

# Google Cloud SDK (ecobee)
if [ -f '/Users/Michael/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/Michael/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/Michael/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/Michael/google-cloud-sdk/completion.zsh.inc'; fi

# Jump to common directories
alias cdh='cd /Users/Michael'
alias cds='cd /Users/Michael/Sites'
alias cde='cd /Users/Michael/Sites/ecobee/consumer-website'
alias cdd='cd /Users/Michael/Sites/projects/dotfiles'
alias cdmu='cd /Users/Michael/Sites/projects/michaeluloth.com'
alias cdgt='cd /Users/Michael/Sites/projects/gatsbytutorials.com'

# Run common ecobee commands
alias yd='yarn install && yarn develop'

alias yt='$(npm bin)/jest --watch' # tests of uncommitted changes
alias yta='$(npm bin)/jest --watchAll' # all tests
ytp() {
   $(npm bin)/jest --watch --testPathPattern=$1 # tests matching pattern
}

alias jw='$(npm bin)/jest --watch' # tests of uncommitted changes
alias jwa='$(npm bin)/jest --watchAll' # all tests
jwp() {
   $(npm bin)/jest --watch --testPathPattern=$1 # tests matching pattern
}

alias gp='git push --no-verify'
alias yb='yarn build'
alias ys='yarn storybook'

