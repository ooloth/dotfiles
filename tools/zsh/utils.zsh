#!/usr/bin/env zsh

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

# Include is_air, is_mini, is_work in this commonly-sourced file
source "${DOTFILES}/tools/macos/shell.zsh"

###########
# GENERAL #
###########

have() {
  if [ -z "$1" ]; then
    echo "Usage: have <command, alias or function>"
    return 1 # false
  fi

  # Check if a command, alias or function with the provided name exists
  if type "$1" &> /dev/null; then
    return 0  # true
  else
    return 1  # false
  fi
}

###############
# COMPLETIONS #
###############

ZSH_COMPLETIONS_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/completions"

# Whether the cached completion FILE is missing or older than COMMAND_PATH. The link counts as well as
# the binary, because a brew cask upgrade points the link at a new version whose binary keeps the
# older time it was built with.
completion_is_stale() {
  local file="$1" command_path="$2"
  [[ -s "$file" ]] || return 0
  [[ "$command_path" -nt "$file" ]] && return 0

  zmodload -F zsh/stat b:zstat
  local -a link_time file_time
  zstat -L -A link_time +mtime -- "$command_path" || return 0
  zstat -A file_time +mtime -- "$file" || return 0
  (( link_time[1] > file_time[1] ))
}

# Registers the completion for COMMAND that GENERATOR prints, such as
# `cached_completion uv uv generate-shell-completion zsh`. The script is kept in a file on fpath, so
# GENERATOR runs only when COMMAND changes, and zsh reads the script only on the first tab after
# COMMAND. Generating and parsing it with eval on every shell start cost up to 85 ms per tool.
cached_completion() {
  local command_name="$1"
  shift
  local command_path="${commands[$command_name]}"
  [[ -n "$command_path" ]] || return 1
  local file="${ZSH_COMPLETIONS_DIR}/_${command_name}"

  if completion_is_stale "$file" "$command_path"; then
    mkdir -p "$ZSH_COMPLETIONS_DIR" || return 1
    local partial="${file}.partial.$$"
    if "$@" >"$partial" 2>/dev/null && [[ -s "$partial" ]]; then
      mv -f "$partial" "$file" || return 1
    else
      rm -f "$partial"
      # A completion from before the failed refresh still works, so it stays registered
      [[ -s "$file" ]] || return 1
    fi
  fi

  (( ${fpath[(Ie)$ZSH_COMPLETIONS_DIR]} )) || fpath=("$ZSH_COMPLETIONS_DIR" $fpath)
  autoload -Uz "_${command_name}"
  compdef "_${command_name}" "$command_name"
}

return_or_exit() {
  local code="$1"                            # The exit code to return or exit with
  return "$code" 2>/dev/null || exit "$code" # return if script is sourced to avoid terminating the parent script; exit if run directly
}

###########
# LOGGING #
###########

# Text colors
# see: https://stackoverflow.com/a/4332530/8802485
TEXT_BLACK=$(tput setaf 0)
TEXT_RED=$(tput setaf 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_YELLOW=$(tput setaf 3)
TEXT_BLUE=$(tput setaf 4)
TEXT_MAGENTA=$(tput setaf 5)
TEXT_CYAN=$(tput setaf 6)
TEXT_WHITE=$(tput setaf 7)
TEXT_BRIGHT=$(tput bold)
TEXT_NORMAL=$(tput sgr0)
TEXT_BLINK=$(tput blink)
TEXT_REVERSE=$(tput smso)
TEXT_UNDERLINE=$(tput smul)

function banner() {
  # Capture the text and color arguments
  local text="$1"
  local color="$2"

  # Define the text and border styles
  local text_color="${TEXT_BRIGHT}$color"
  local border_color="${TEXT_NORMAL}$color"
  local border_char_top_left_corner="╔"
  local border_char_top_right_corner="╗"
  local border_char_bottom_right_corner="╝"
  local border_char_bottom_left_corner="╚"
  local border_char_horizontal="═"
  local border_char_vertical="║"

  # Calculate the width of the text, adding one extra column per emoji (since they generally occupy two columns onscreen)
  local char_count=${#text}
  local emoji_count=$(echo -n "$text" | python3 -c "import sys, unicodedata; print(sum((unicodedata.category(ch) == 'So') for ch in sys.stdin.read()))")
  local padding_left=1
  local padding_right=1
  local text_cols=$((padding_left + char_count + emoji_count + padding_right))

  # Build the banner components
  local border_top="$border_color$border_char_top_left_corner$(repeat $text_cols; printf $border_char_horizontal)$border_char_top_right_corner"
  local border_vertical="$border_color$border_char_vertical"
  local border_bottom="$border_color$border_char_bottom_left_corner$(repeat $text_cols; printf $border_char_horizontal)$border_char_bottom_right_corner"
  local text="$text_color $text "

  # Output the assembled banner
  printf "\n$border_top\n$border_vertical$text$border_vertical\n$border_bottom\n\n${TEXT_NORMAL}"
}

function info() {
  local text="$1"
  local color="${TEXT_WHITE}"
  banner "${text}" "${color}"
}

function warn() {
  local text="$1"
  local color="${TEXT_YELLOW}"
  banner "${text}" "${color}"
}

function error() {
  local text="$1"
  local color="${TEXT_RED}"
  banner "${text}" "${color}"
}

function debug() {
  local text="$1"
  printf "\n%s\n" "$text" >&2
}
