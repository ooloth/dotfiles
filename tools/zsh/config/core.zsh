# Core zsh configuration: environment, options, history, completions, aliases

#########################
# ENVIRONMENT VARIABLES #
#########################

# Path
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:${PATH}" # Default system paths
export PATH="/opt/local/bin:/opt/local/sbin:${PATH}" # Add MacPorts to PATH
export PATH="${HOME}/.local/bin:${PATH}" # Add local bin to PATH

# General
export EDITOR=nvim
export SHELL=/opt/homebrew/bin/zsh
export XDG_CONFIG_HOME="${HOME}/.config"

# History variables
export HISTFILE="${HOME}/.zsh_history"
export HISTORY_IGNORE="git*"
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE

###########
# OPTIONS #
###########

# see: https://ryantoddgarza.medium.com/a-better-zsh-history-pt-2-dde323e0c9ca
# see: https://www.reddit.com/r/zsh/comments/wy0sm6/what_is_your_history_configuration/
# see: https://zsh.sourceforge.io/Doc/Release/Parameters.html#Parameters-Used-By-The-Shell
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt INC_APPEND_HISTORY        # Record events as soon as they happen instead of waiting until the shell exits (so I can reload the shell without losing history).
setopt SHARE_HISTORY             # Share history between all sessions.

# enable vi mode
bindkey -v

# restore history search while in vi mode
# bindkey ^R history-incremental-search-backward
# bindkey ^S history-incremental-search-forward

###############
# COMPLETIONS #
###############

# Must come before compinit to support rust tab completions
# See: https://rust-lang.github.io/rustup/installation/index.html
fpath+=~/.zfunc

# Initialize zsh completion before invoking tool-specific completions
# See: https://stackoverflow.com/questions/66338988/complete13-command-not-found-compde
autoload -Uz compinit && compinit
autoload -Uz bashcompinit && bashcompinit

# Third-party core completions
if have brew; then
  source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

###########
# ALIASES
###########

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias c="clear"

# Crontab
alias cte="EDITOR=nvim crontab -e"
alias ctl="crontab -l"

alias env="env | sort"

kill() {
  local port="${1}"
  lsof -t -i:"${port}" | xargs kill -9;
}

alias R="source ${HOME}/.zshenv && source ${HOME}/.zshrc" # see https://stackoverflow.com/questions/56284264/recommended-method-for-reloading-zshrc-source-vs-exec

alias regen="source ${DOTFILES}/features/update/zsh/generate-manifest.zsh" # regenerate shell manifest (rarely needed - happens automatically when stale)

sl() {
  local source_file="$1"
  local target_dir="$2"

  mkdir -p "$target_dir"
  printf "🔗 " # prefix (no newline included)
  ln -fsvw "$source_file" "$target_dir";
}

alias x="exit"

zt() {
  # [z]sh [t]ime: measure how long new shells take to launch
  for i in $(seq 1 10); do
    time zsh -i -c exit
  done
}

