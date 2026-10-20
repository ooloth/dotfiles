#!/usr/bin/env bash

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

# Include is_air, is_mini, is_work in this commonly-sourced file
source "${DOTFILES}/tools/macos/utils.bash"

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

  local file_name
  file_name="$(basename "$source_file")"
  local target_path="$target_dir/$file_name"

  # In check mode: report status without creating anything
  if [[ "${DOTFILES_CHECK:-}" == "true" ]]; then
    if [[ ! -e "$source_file" ]]; then
      printf "❌ MISSING source: %s\n" "$source_file"
      return 1
    fi
    if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "$source_file" ]]; then
      printf "✅ OK      %s → %s\n" "$file_name" "$target_dir"
      return 0
    elif [[ -L "$target_path" ]]; then
      printf "❌ WRONG TARGET: %s → %s (points to: %s)\n" "$file_name" "$target_dir" "$(readlink "$target_path")"
      return 1
    else
      printf "❌ MISSING: %s → %s\n" "$file_name" "$target_dir"
      return 1
    fi
  fi

  if [[ ! -e "$source_file" ]]; then
    echo "Error: Source file does not exist: $source_file" >&2
    return 1
  fi

  # Check if the target file exists and is a symlink pointing to the correct source file
  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_file" ]; then
    printf "✅ $file_name → $target_dir\n"
    return 0
  fi

  mkdir -p "$target_dir"

  printf "🔗 " # inline prefix for the output of the next line
  ln -fsvw "$source_file" "$target_dir"
}

# Every tools/<tool>/link.bash in alphabetical order by tool, one per line. tools/@new and
# tools/@archive are a template and retired tools, and a link.bash deeper than a tool's root is a
# draft, so neither is listed. `symlinks` runs this list and scripts/checks/link-scripts.bash checks it.
link_scripts() {
  local script found=0
  for script in "${DOTFILES}"/tools/*/link.bash; do
    [[ -f "${script}" ]] || continue
    [[ "${script}" == "${DOTFILES}/tools/@"* ]] && continue
    printf "%s\n" "${script}"
    found=$((found + 1))
  done

  # Every tool linking nothing only happens when DOTFILES points somewhere other than the repo
  if [[ "${found}" -eq 0 ]]; then
    echo "🚨 Error: no tools/*/link.bash found under DOTFILES='${DOTFILES:-}'" >&2
    return 1
  fi
}

# Directories swept for any broken symlink, since only links this repo made are expected there.
any_broken_symlink_dirs() {
  printf "%s\n" "${HOME}" "${HOME}/.config" "${HOME}/Library/Application Support/Code/User"
}

# Directories other tools also link into, swept only for broken links into this repo.
# scripts/checks/link-scripts.bash fails when a link.bash links into a directory neither list covers.
repo_symlink_dirs() {
  printf "%s\n" "${HOME}/.claude" "${HOME}/.agents" "${HOME}/.codex" "${HOME}/.local/bin" \
    "${HOME}/.config/pi/agent"
}

# How many levels deep the sweep looks in a directory. ~/.config is swept two levels deep, so a
# tool's own folder under it is covered too.
symlink_sweep_depth() {
  [[ "${1:-}" == "${HOME}/.config" ]] && echo 2 || echo 1
}

# Whether the sweep in `symlinks` reaches a link placed directly in this directory.
is_swept_link_dir() {
  local dir="${1:-}" swept
  while IFS= read -r swept; do
    [[ "${dir}" == "${swept}" ]] && return 0
    [[ "$(symlink_sweep_depth "${swept}")" -ge 2 && "$(dirname "${dir}")" == "${swept}" ]] && return 0
  done < <(any_broken_symlink_dirs; repo_symlink_dirs)
  return 1
}

# Removes broken symlinks in a directory, whatever they point at.
remove_broken_symlinks() {
  local directory="${1:-}"
  local max_depth
  max_depth="$(symlink_sweep_depth "${directory}")"

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

# Removes broken symlinks in a directory that point into this repo, leaving other tools' links alone.
remove_broken_repo_symlinks() {
  local directory="${1:-}"

  # An empty or relative DOTFILES would make every link look like it points into the repo
  if [[ "${DOTFILES:-}" != /* || ! -d "${DOTFILES}" ]]; then
    echo "🚨 Error: DOTFILES must be an absolute path to the repo, got '${DOTFILES:-}'" >&2
    return 1
  fi

  if [[ -z "${directory}" ]]; then
    echo "🚨 Error: Directory path is required" >&2
    return 1
  fi

  if [[ ! -d "${directory}" ]]; then
    return 0
  fi

  local symlink
  while IFS= read -r -d '' symlink; do
    if [[ "$(readlink "${symlink}")" == "${DOTFILES}/"* && ! -e "${symlink}" ]]; then
      printf "🧼 Removing broken symlink: ${symlink}\n"
      trash "${symlink}"
    fi
  done < <(find "${directory}" -maxdepth "$(symlink_sweep_depth "${directory}")" -type l -print0 \
    2>/dev/null)

  return 0
}

###########
# LOGGING #
###########

# Text colors, empty when there is no terminal to ask (CI, cron, launchd), so a script sourcing
# this under `set -e` prints plain text instead of exiting
# see: https://stackoverflow.com/a/4332530/8802485
TEXT_RED=$(tput setaf 1 2>/dev/null || true)
TEXT_YELLOW=$(tput setaf 3 2>/dev/null || true)
TEXT_WHITE=$(tput setaf 7 2>/dev/null || true)
TEXT_BRIGHT=$(tput bold 2>/dev/null || true)
TEXT_NORMAL=$(tput sgr0 2>/dev/null || true)
# TEXT_BLACK=$(tput setaf 0 2>/dev/null || true)
# TEXT_GREEN=$(tput setaf 2 2>/dev/null || true)
# TEXT_BLUE=$(tput setaf 4 2>/dev/null || true)
# TEXT_MAGENTA=$(tput setaf 5 2>/dev/null || true)
# TEXT_CYAN=$(tput setaf 6 2>/dev/null || true)
# TEXT_BLINK=$(tput blink 2>/dev/null || true)
# TEXT_REVERSE=$(tput smso 2>/dev/null || true)
# TEXT_UNDERLINE=$(tput smul 2>/dev/null || true)

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
  emoji_count=$(printf '%s' "$text" | perl -CS -0777 -ne 'print scalar(() = /\p{So}/g)')
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
