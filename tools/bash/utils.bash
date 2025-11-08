#!/usr/bin/env bash
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

# Include is_air, is_mini, is_work in this commonly-sourced file
source "${DOTFILES}/tools/macos/shell/aliases.zsh"

##############
# INSPECTING #
##############

have() {
  if [ -z "$1" ]; then
    echo "Usage: have <command, alias or function>" >&2
    return 1 # false
  fi

  # Check if a command, alias or function with the provided name exists
  if type "$1" &>/dev/null; then
    return 0 # true
  else
    return 1 # false
  fi
}

is_sourced() {
  # Returns 0 if sourced, 1 if executed
  [[ "${BASH_SOURCE[0]}" != "$0" ]]
}

return_or_exit() {
  local code="${1:-0}"
  if is_sourced; then
    return "$code"
  else
    exit "$code"
  fi
}

##############
# SYMLINKING #
##############

symlink() {
  # Both arguments should be absolute paths
  local source_file="${1:-}"
  local target_dir="${2:-}"

  if [[ -z "$source_file" ]]; then
    echo "Error: Source file path is required" >&2
    return 1
  fi

  if [[ -z "$target_dir" ]]; then
    echo "Error: Target directory path is required" >&2
    return 1
  fi

  if [[ ! -e "$source_file" ]]; then
    echo "Error: Source file does not exist: $source_file" >&2
    return 1
  fi

  local file_name="$(basename "$source_file")"
  local target_path="$target_dir/$file_name"

  # Check if the target file exists and is a symlink pointing to the correct source file
  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_file" ]; then
    printf "✅ $file_name → $target_dir\n"
    return 0
  fi

  mkdir -p "$target_dir"

  printf "🔗 " # inline prefix for the output of the next line
  ln -fsvw "$source_file" "$target_dir"
}

remove_broken_symlinks() {
  local directory="${1:-}"

  # Remove broken symlinks at the top level of ~/.config subdirectories too
  local max_depth=$([[ "${directory}" == *".config"* ]] && echo 2 || echo 1)

  if [[ -z "${directory}" ]]; then
    echo "🚨 Error: Directory path is required" >&2
    return 1
  fi

  if [[ ! -d "${directory}" ]]; then
    printf "⚠️ Directory does not exist: ${directory}\n" >&2
    return 0
  fi

  # Find all symlinks in directory and check if they're broken
  local symlink
  while IFS= read -r -d '' symlink; do
    # Check if symlink target exists
    if [[ ! -e "${symlink}" ]]; then
      printf "🧼 Removing broken symlink: ${symlink}\n"
      trash "${symlink}"
    fi
  done < <(find "${directory}" -maxdepth "${max_depth}" -type l -print0 2>/dev/null)

  return 0
}

###########
# LOGGING #
###########

# Text colors
# see: https://stackoverflow.com/a/4332530/8802485
TEXT_RED=$(tput setaf 1)
TEXT_YELLOW=$(tput setaf 3)
TEXT_WHITE=$(tput setaf 7)
TEXT_BRIGHT=$(tput bold)
TEXT_NORMAL=$(tput sgr0)
# TEXT_BLACK=$(tput setaf 0)
# TEXT_GREEN=$(tput setaf 2)
# TEXT_BLUE=$(tput setaf 4)
# TEXT_MAGENTA=$(tput setaf 5)
# TEXT_CYAN=$(tput setaf 6)
# TEXT_BLINK=$(tput blink)
# TEXT_REVERSE=$(tput smso)
# TEXT_UNDERLINE=$(tput smul)

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
  local emoji_count=$(echo -n "$text" | python3 -c "import sys, unicodedata; print(sum((unicodedata.category(ch) == 'So') for ch in sys.stdin.read()))")
  local char_count=${#text}
  local padding_left=1
  local padding_right=1
  local text_cols=$((padding_left + char_count + emoji_count + padding_right))

  # Build the banner components
  local horizontal_line=$(for _char in $(seq $text_cols); do printf "${border_char_horizontal}"; done)
  local border_top="$border_color$border_char_top_left_corner$horizontal_line$border_char_top_right_corner"
  local border_bottom="$border_color$border_char_bottom_left_corner$horizontal_line$border_char_bottom_right_corner"
  local border_vertical="$border_color$border_char_vertical"

  local text="$text_color $text "

  # Output the assembled banner
  printf "\n${border_top}\n${border_vertical}${text}${border_vertical}\n${border_bottom}\n\n${TEXT_NORMAL}" >&2
}

# TODO: use "h1", "h2", "h3" functions for different logging header designs? h2 being maybe just the bold + underline? h3 being just bold? info/warn/error being normal text but colored? and maybe prefixed?
# TODO: migrate logging behaviour from bash/utils.bash into bash/logging/banner.bash, bash/logging/h1.bash, etc and source all those files in bash/utils.bash?
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
