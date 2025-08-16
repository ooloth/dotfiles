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
    local feature_path="$DOTFILES/features/$feature_name/update.bash"
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
            --help|-h)
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
    cat << EOF
Usage: update.bash [feature]

Update dotfiles components. If no feature is specified, updates all components.

Available features:
  homebrew    - Update Homebrew packages and casks
  macos       - Update macOS system software
  neovim      - Update Neovim plugins
  node        - Update Node.js via fnm
  npm         - Update global npm packages
  rust        - Update Rust toolchain
  tmux        - Update tmux plugins
  yazi        - Update yazi flavors
  symlinks    - Update symlinks
  ssh         - Update SSH configuration
  git         - Update git configuration
  github      - Update GitHub CLI
  uv          - Update uv Python package manager
  content     - Update content repository
  settings    - Update macOS settings

Examples:
  update.bash           # Update everything
  update.bash homebrew  # Update only Homebrew
  update.bash neovim    # Update only Neovim

EOF
}

# Main update function
main() {
    local feature
    feature=$(parse_arguments "$@")
    
    # Initialize utilities
    if [[ -f "$DOTFILES/core/detection/machine.bash" ]]; then
        source "$DOTFILES/core/detection/machine.bash"
        init_machine_detection
    fi
    
    if [[ -f "$DOTFILES/core/errors/handling.bash" ]]; then
        source "$DOTFILES/core/errors/handling.bash"
    fi
    
    # If a specific feature was requested, update only that
    if [[ -n "$feature" ]]; then
        printf "🔄 Updating %s...\n\n" "$feature"
        run_updater "$feature"
        printf "\n✅ Update complete!\n"
        return 0
    fi
    
    # Otherwise, update everything
    printf "🔄 Updating all dotfiles components...\n\n"
    
    # Update order matters for some dependencies
    printf "📦 Updating package managers...\n"
    run_updater "homebrew"
    run_updater "rust"
    run_updater "node"
    run_updater "uv"
    
    printf "\n🛠️  Updating development tools...\n"
    run_updater "npm"
    run_updater "neovim"
    run_updater "tmux"
    run_updater "yazi"
    
    printf "\n⚙️  Updating configurations...\n"
    run_updater "ssh"
    run_updater "git"
    run_updater "github"
    run_updater "symlinks"
    run_updater "content"
    
    printf "\n💻 Updating system settings...\n"
    run_updater "macos"
    run_updater "settings"
    
    printf "\n✅ All updates complete!\n"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi