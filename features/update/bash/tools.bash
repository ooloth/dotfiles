#!/usr/bin/env bash
set -euo pipefail

export DOTFILES="$HOME/Repos/ooloth/dotfiles"

run_updater() {
  local tool_name="$1"
  local tool_path="${DOTFILES}/tools/${tool_name}/update.bash"

  # Try new feature location first
  if [[ -f "$tool_path" ]]; then
    printf "  → Using tool-based updater: %s\n" "$tool_path"
    source "$tool_path"
  else
    printf "  ⚠️  No updater found for %s\n" "$tool_name"
    # Don't fail, just warn - not all features need update scripts
    return 0
  fi
}

show_help() {
  cat <<EOF
Usage: features/update/tools.bash [feature]

Update dotfiles components. If no tool is specified, updates frequently-changing tools.

Examples:
  features/update/tools.bash           # Update all frequent-update components
  features/update/tools.bash homebrew  # Update only Homebrew
  features/update/tools.bash ssh       # Manually update SSH (not usually included in full update)

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

  # Update in the same order as legacy features/update/update.zsh
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

main "$@"
