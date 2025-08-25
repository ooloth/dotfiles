#!/usr/bin/env bash
set -euo pipefail

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
  local emoji_count
  emoji_count=$(echo -n "$text" | python3 -c "import sys, unicodedata; print(sum((unicodedata.category(ch) == 'So') for ch in sys.stdin.read()))")
  local char_count=${#text}
  local padding_left=1
  local padding_right=1
  local text_cols=$((padding_left + char_count + emoji_count + padding_right))

  # Build the banner components
  local horizontal_line
  horizontal_line=$(for _char in $(seq $text_cols); do printf "${border_char_horizontal}"; done)

  local border_top="$border_color$border_char_top_left_corner$horizontal_line$border_char_top_right_corner"
  local border_bottom="$border_color$border_char_bottom_left_corner$horizontal_line$border_char_bottom_right_corner"
  local border_vertical="$border_color$border_char_vertical"

  local text="$text_color $text "

  # Output the assembled banner
  printf "\n${border_top}\n${border_vertical}${text}${border_vertical}\n${border_bottom}\n\n${TEXT_NORMAL}"
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
