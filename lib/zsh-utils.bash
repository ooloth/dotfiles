#!/usr/bin/env bash
# Utilities for managing Zsh shell installation and configuration

set -euo pipefail

# Check if Homebrew's Zsh is installed
is_homebrew_zsh_installed() {
  local shell_path="/opt/homebrew/bin/zsh"
  [[ -x "$shell_path" ]]
}

# Check if a shell path is in /etc/shells
is_shell_registered() {
  local shell_path="$1"
  grep -q "^${shell_path}$" /etc/shells 2>/dev/null
}

# Add shell to /etc/shells
add_shell_to_etc_shells() {
  local shell_path="$1"
  
  if is_shell_registered "$shell_path"; then
    return 0
  fi
  
  echo "📄 Adding '${shell_path}' to /etc/shells"
  if ! sudo sh -c "echo ${shell_path} >> /etc/shells"; then
    echo "❌ Failed to add shell to /etc/shells"
    return 1
  fi
}

# Change user's default shell
change_user_shell() {
  local shell_path="$1"
  local username="${2:-$USER}"
  
  echo "🐚 Changing shell to $shell_path for user $username..."
  if ! sudo chsh -s "$shell_path" "$username"; then
    echo "❌ Failed to change shell"
    return 1
  fi
}

# Get current user's shell
get_user_shell() {
  local username="${1:-$USER}"
  dscl . -read "/Users/$username" UserShell 2>/dev/null | awk '{print $2}'
}

# Check if user is already using specified shell
is_user_using_shell() {
  local shell_path="$1"
  local username="${2:-$USER}"
  local current_shell
  
  current_shell=$(get_user_shell "$username")
  [[ "$current_shell" == "$shell_path" ]]
}