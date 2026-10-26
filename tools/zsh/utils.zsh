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

# Writes what COMMAND prints to FILE, or leaves FILE as it was when COMMAND fails or prints nothing.
write_cache() {
  local file="$1"
  shift
  mkdir -p "${file:h}" || return 1
  local partial="${file}.partial.$$"
  if "$@" >"$partial" 2>/dev/null && [[ -s "$partial" ]]; then
    mv -f "$partial" "$file"
  else
    rm -f "$partial"
    return 1
  fi
}

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

  # A completion from before a failed refresh still works, so it stays registered
  if completion_is_stale "$file" "$command_path"; then
    write_cache "$file" "$@" || [[ -s "$file" ]] || return 1
  fi

  (( ${fpath[(Ie)$ZSH_COMPLETIONS_DIR]} )) || fpath=("$ZSH_COMPLETIONS_DIR" $fpath)
  autoload -Uz "_${command_name}"
  compdef "_${command_name}" "$command_name"
}

BREW_SHELLENV_CACHE="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/brew-shellenv.zsh"

# Applies `BREW shellenv zsh` from a cache, because running brew cost 17 ms per shell start.
# tools/homebrew/update.bash deletes the cache after upgrading Homebrew, so the next shell writes it
# again.
load_brew_shellenv() {
  local brew="$1"
  if [[ ! -s "$BREW_SHELLENV_CACHE" ]]; then
    write_cache "$BREW_SHELLENV_CACHE" "$brew" shellenv zsh || return 1
  fi
  source "$BREW_SHELLENV_CACHE"
}

# Sets reply to the shell.zsh of every feature and tool, in the order .zshrc sources them
# (tools/zsh/config/tools.zsh). A glob, because running find cost 14 ms per shell start. @new is the
# template and @archive holds retired tools, so neither is sourced.
shell_config_files() {
  # null_glob rather than the (N) qualifier, so bash can still parse this file
  setopt local_options null_glob
  reply=()
  local file
  for file in "${DOTFILES}"/{features,tools}/*/shell.zsh; do
    [[ "$file" == */@new/* || "$file" == */@archive/* ]] || reply+=("$file")
  done
}

return_or_exit() {
  local code="$1"                            # The exit code to return or exit with
  return "$code" 2>/dev/null || exit "$code" # return if script is sourced to avoid terminating the parent script; exit if run directly
}

###########
# LOGGING #
###########

# Text colors: what `tput setaf 0`, `tput bold` and so on print for xterm-256color, written out because
# running tput 13 times cost 20 ms per shell start
TEXT_BLACK=$'\e[30m'
TEXT_RED=$'\e[31m'
TEXT_GREEN=$'\e[32m'
TEXT_YELLOW=$'\e[33m'
TEXT_BLUE=$'\e[34m'
TEXT_MAGENTA=$'\e[35m'
TEXT_CYAN=$'\e[36m'
TEXT_WHITE=$'\e[37m'
TEXT_BRIGHT=$'\e[1m'
TEXT_NORMAL=$'\e(B\e[m'
TEXT_BLINK=$'\e[5m'
TEXT_REVERSE=$'\e[7m'
TEXT_UNDERLINE=$'\e[4m'

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
