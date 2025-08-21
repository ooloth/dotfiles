#!/usr/bin/env bash

# Dotfiles update script (bash version)
# Main entry point for updating dotfiles components

# Enable strict error handling
set -euo pipefail

# Set up environment
export DOTFILES="$HOME/Repos/ooloth/dotfiles"

# Feature discovery function for updates
# Tries new feature location first, falls back to old location
run_updater() {
    local feature_name="$1"
    local feature_path="$DOTFILES/$feature_name/update.bash"
    local legacy_path="$DOTFILES/bin/update/${feature_name}.zsh"

    # Try new feature location first
    if [[ -f "$feature_path" ]]; then
        printf "  → Using feature-based updater: %s\n" "$feature_path"
        source "$feature_path"
    # Fall back to old location
    elif [[ -f "$legacy_path" ]]; then
        printf "  → Using legacy updater: %s\n" "$legacy_path"
        source "$legacy_path"
    else
        printf "  ⚠️  No updater found for %s\n" "$feature_name"
        # Don't fail, just warn - not all features need update scripts
        return 0
    fi
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

# Show help message
show_help() {
    cat <<EOF
Usage: update.bash [feature]

Update dotfiles components. If no feature is specified, updates frequently-changing components.

Available features (frequent updates):
  mode        - Update mode/environment settings
  symlinks    - Update symlinks
  rust        - Update Rust toolchain
  yazi        - Update yazi flavors
  neovim      - Update Neovim plugins
  tmux        - Update tmux plugins
  node        - Update Node.js and global npm packages
  gcloud      - Update Google Cloud SDK
  homebrew    - Update Homebrew packages and casks
  macos       - Update macOS system software

Available features (manual updates):
  ssh         - Update SSH configuration
  git         - Update git configuration
  github      - Update GitHub CLI
  uv          - Update uv Python package manager
  content     - Update content repository
  settings    - Update macOS settings
  node        - Update Node.js via fnm

Examples:
  update.bash           # Update all frequent-update components
  update.bash homebrew  # Update only Homebrew
  update.bash ssh       # Manually update SSH (not included in full update)

EOF
}

# Main update function
main() {
    local feature
    feature=$(parse_arguments "$@")

    # Initialize utilities
    if [[ -f "$DOTFILES/@common/detection/machine.bash" ]]; then
        source "$DOTFILES/@common/detection/machine.bash"
        init_machine_detection
    fi

    if [[ -f "$DOTFILES/@common/errors/handling.bash" ]]; then
        source "$DOTFILES/@common/errors/handling.bash"
    fi

    # If a specific feature was requested, update only that
    if [[ -n "$feature" ]]; then
        printf "🔄 Updating %s...\n\n" "$feature"
        run_updater "$feature"
        printf "\n✅ Update complete!\n"
        return 0
    fi

    # Otherwise, update frequently-changing components
    printf "🔄 Updating frequently-changing dotfiles components...\n\n"

    # Update in the same order as legacy zsh/config/update.zsh
    run_updater "mode"
    run_updater "symlinks"
    run_updater "rust"
    run_updater "yazi"
    run_updater "neovim"
    run_updater "tmux"
    run_updater "node"
    run_updater "gcloud"
    run_updater "homebrew"
    run_updater "macos"

    printf "\n✅ All frequent updates complete!\n"
    printf "\nNote: Some components require manual updates:\n"
    printf "  - SSH keys/config: ./update.bash ssh\n"
    printf "  - Git configuration: ./update.bash git\n"
    printf "  - System settings: ./update.bash settings\n"
    printf "  - Content repositories: ./update.bash content\n"
}

# If executed directly, run main; otherwise (i.e. if sourced), make the functions
# and variables available in the current shell but don't execute any logic
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
