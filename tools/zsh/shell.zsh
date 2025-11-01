source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

########################
# ENVIROMENT VARIABLES #
########################

# Path
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:${PATH}" # Default system paths
export PATH="/opt/local/bin:/opt/local/sbin:${PATH}" # Add MacPorts to PATH
export PATH="${HOME}/.local/bin:${PATH}" # Add local bin to PATH

# History
export HISTFILE="${HOME}/.zsh_history"
export HISTORY_IGNORE="git*"
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE

# General
export EDITOR=nvim
export SHELL=/opt/homebrew/bin/zsh
export XDG_CONFIG_HOME="${HOME}/.config"

###########
# ALIASES #
###########

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias c="clear"
alias env="env | sort"

kill() {
  local port="${1}"
  lsof -t -i:"${port}" | xargs kill -9;
}

alias R="source ${HOME}/.zshenv && source ${HOME}/.zshrc" # see https://stackoverflow.com/questions/56284264/recommended-method-for-reloading-zshrc-source-vs-exec

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

###############
# COMPLETIONS #
###############

if have brew; then
  source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
