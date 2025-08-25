#!/usr/bin/env bash

set -euo pipefail

# Set up environment
export DOTFILES="$HOME/Repos/ooloth/dotfiles"

# Feature discovery function for updates
# Tries new feature location first, falls back to old location
run_updater() {
  local tool_name="$1"
  local tool_path="${DOTFILES}/tools/${tool_name}/update.bash"
  local legacy_path="${DOTFILES}/bin/update/${tool_name}.zsh"

  # Try new feature location first
  if [[ -f "$tool_path" ]]; then
    printf "  → Using tool-based updater: %s\n" "$tool_path"
    source "$tool_path"
  # Fall back to old location
  elif [[ -f "$legacy_path" ]]; then
    printf "  → Using legacy updater: %s\n" "$legacy_path"
    source "$legacy_path"
  else
    printf "  ⚠️  No updater found for %s\n" "$tool_name"
    # Don't fail, just warn - not all features need update scripts
    return 0
  fi
}

show_help() {
  cat <<EOF
Usage: features/update/update.bash [feature]

Update dotfiles components. If no tool is specified, updates frequently-changing tools.

Examples:
  features/update/update.bash           # Update all frequent-update components
  features/update/update.bash homebrew  # Update only Homebrew
  features/update/update.bash ssh       # Manually update SSH (not usually included in full update)

EOF
}

# Parse command line arguments
parse_arguments() {
  local feature=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --help | -h)
      show_help
      exit 0
      ;;
    *)
      feature="$1"
      shift
      ;;
    esac
  done

  echo "$feature"
}

main() {
  local feature
  feature=$(parse_arguments "$@")

  # Initialize utilities
  source "$DOTFILES/features/common/detection/machine.bash"
  source "$DOTFILES/features/common/errors/handling.bash"

  init_machine_detection

  # If a specific feature was requested, update only that
  if [[ -n "$feature" ]]; then
    printf "🔄 Updating %s...\n\n" "$feature"
    run_updater "$feature"
    printf "\n✅ Update complete!\n"
    return 0
  fi

  # Otherwise, update frequently-changing components
  printf "🔄 Updating frequently-changing components...\n\n"

  # Update in the same order as legacy tools/zsh/config/update.zsh
  run_updater "mode"
  run_updater "symlinks"
  run_updater "uv"
  run_updater "harlequin"
  run_updater "visidata"
  run_updater "rust"
  run_updater "neovim"
  run_updater "tmux"
  run_updater "node"
  run_updater "gcloud"
  run_updater "homebrew"
  run_updater "macos"
}

# If executed directly, run main; otherwise (i.e. if sourced), make the functions
# and variables available in the current shell but don't execute any logic
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
