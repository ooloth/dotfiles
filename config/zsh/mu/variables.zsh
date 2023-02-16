# See: https://stackoverflow.com/questions/1371261/get-current-directory-or-folder-name-without-the-full-path
export CURRENT_DIRECTORY=${PWD##*/}

export EDITOR=nvim
export GOKU_EDN_CONFIG_FILE=$HOME/.config/karabiner/karabiner.edn
export K9SCONFIG=$HOME/.config/k9s

# TODO: customize HISTORY behavior (validate ideas below + use with fzf?)
# export HISTSIZE=10000
# SAVEHIST=10000
# export HISTCONTROL=ignoreboth:erasedups
# export HISTORY_IGNORE="git*"
# setopt EXTENDED_HISTORY
# setopt HIST_IGNORE_SPACE
# setopt HIST_IGNORE_ALL_DUPS
# alias history='history 0'
# alias h='history | grep'
#
export PATH=/usr/local/bin:$PATH # Add Homebrew's executable directory to front of PATH
export PATH=$HOME/.local/bin:$PATH # Add lvim location to PATH
export PATH=$HOME/.cargo/bin:$PATH # Add cargo to PATH (for lvim)

export STARSHIP_CONFIG=$HOME/.config/starship/config.toml

IS_WORK_LAPTOP=false
if [[ -d "$HOME/Repos/recursionpharma" ]]; then IS_WORK_LAPTOP=true; fi

