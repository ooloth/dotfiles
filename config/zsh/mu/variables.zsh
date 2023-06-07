export EDITOR=code

export GOKU_EDN_CONFIG_FILE=$HOME/.config/karabiner/karabiner.edn

export IS_WORK_LAPTOP=$( [[ -d "$HOME/Repos/recursionpharma" ]] && echo "true" || echo "false" )

export K9SCONFIG=$HOME/.config/k9s

# TODO: customize HISTORY behavior (validate ideas below + use with fzf?)
export HISTSIZE=10000
SAVEHIST=10000
export HISTCONTROL=ignoreboth:erasedups
export HISTORY_IGNORE="git*"
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS
# alias history='history 0'
# alias h='history | grep'

export PATH=/usr/local/bin:$PATH # Add Homebrew's executable directory to front of PATH

export SHELL=$(which zsh)

export STARSHIP_CONFIG=$HOME/.config/starship/config.toml

# enable vi mode
bindkey -v
# restore history search while in vi mode
# bindkey ^R history-incremental-search-backward
# bindkey ^S history-incremental-search-forward

# see: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#user-config
export XDG_CONFIG_HOME=$HOME/.config
