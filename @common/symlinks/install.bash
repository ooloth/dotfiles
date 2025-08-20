#!/usr/bin/env bash

set -euo pipefail

# Source utility functions
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_root="$(cd "$script_dir/../.." && pwd)"

source "$dotfiles_root/@common/symlinks/utils.bash"

# Configuration paths
DOTFILES="$dotfiles_root"
DOTCONFIG="$DOTFILES/config"
HOMECONFIG="$HOME/.config"

# Main symlink creation function
create_dotfiles_symlinks() {
    echo "🔗 Creating dotfiles symlinks..."

    # Remove broken symlinks first
    echo "🧹 Cleaning up broken symlinks..."
    remove_broken_symlinks "$HOME"
    remove_broken_symlinks "$HOMECONFIG"

    echo "🏠 Creating home directory symlinks..."

    # Create symlinks for home directory files
    maybe_symlink "${DOTFILES}/claude/config/agents" "${HOME}/.claude"
    maybe_symlink "${DOTFILES}/claude/config/CLAUDE.md" "${HOME}/.claude"
    maybe_symlink "${DOTFILES}/claude/config/commands" "${HOME}/.claude"
    maybe_symlink "${DOTFILES}/claude/config/settings.json" "${HOME}/.claude"
    maybe_symlink "${DOTFILES}/zsh/config/.hushlogin" "${HOME}"
    maybe_symlink "${DOTFILES}/zsh/config/.zshenv" "${HOME}"

    echo "⚙️  Creating config directory symlinks..."

    # Create symlinks for all config files
    create_config_symlinks

    echo "📚 Creating Library symlinks..."

    # Create VS Code symlinks
    create_vscode_symlinks

    # Create Yazi symlinks if available
    create_yazi_symlinks

    echo "✅ All dotfiles symlinks created successfully"
}

# Create symlinks for config directory files
create_config_symlinks() {
    # Ensure config directory exists
    mkdir -p "$HOMECONFIG"

    # Find all files in config directory and create symlinks
    if command -v fd >/dev/null 2>&1; then
        # Use fd if available (faster and more reliable)
        while IFS= read -r -d '' file; do
            local relpath="${file#"$DOTCONFIG"/}"
            local dirpath
            dirpath="$(dirname "$relpath")"
            local targetdir="$HOMECONFIG/$dirpath"

            maybe_symlink "$file" "$targetdir"
        done < <(fd --type file --hidden . "$DOTCONFIG" --print0 2>/dev/null)
    else
        # Fallback to find command
        while IFS= read -r -d '' file; do
            local relpath="${file#"$DOTCONFIG"/}"
            local dirpath
            dirpath="$(dirname "$relpath")"
            local targetdir="$HOMECONFIG/$dirpath"

            maybe_symlink "$file" "$targetdir"
        done < <(find "$DOTCONFIG" -type f -print0 2>/dev/null)
    fi
}

# Create VS Code symlinks
create_vscode_symlinks() {
    local vscode_user="$HOME/Library/Application Support/Code/User"

    # Check if VS Code directory exists
    if [[ ! -d "$vscode_user" ]]; then
        echo "📝 VS Code not found, skipping VS Code symlinks"
        return 0
    fi

    local vscode_files=(
        "$DOTFILES/library/vscode/settings.json"
        "$DOTFILES/library/vscode/keybindings.json"
        "$DOTFILES/library/vscode/snippets"
    )

    for file in "${vscode_files[@]}"; do
        if [[ -e "$file" ]]; then
            maybe_symlink "$file" "$vscode_user"
        else
            echo "⚠️  Skipping missing VS Code file: $file"
        fi
    done
}

# Create Yazi symlinks if available
create_yazi_symlinks() {
    local yazi_flavors="$HOME/Repos/yazi-rs/flavors"

    if [[ ! -d "$yazi_flavors" ]]; then
        echo "🗂️  Yazi flavors not found, skipping Yazi symlinks"
        return 0
    fi

    # Create symlink for Catppuccin Mocha theme
    local catppuccin_theme="$yazi_flavors/catppuccin-mocha.yazi"
    if [[ -d "$catppuccin_theme" ]]; then
        maybe_symlink "$catppuccin_theme" "$HOMECONFIG/yazi/flavors"
    else
        echo "⚠️  Catppuccin Mocha theme not found at $catppuccin_theme"
    fi
}

# Verify symlinks were created correctly
verify_symlinks() {
    echo "🔍 Verifying symlinks..."

    local verification_failed=false

    # Check critical symlinks
    local critical_symlinks=(
        "$HOME/.zshenv:$DOTFILES/zsh/config/.zshenv"
        "$HOMECONFIG/nvim/init.lua:$DOTFILES/config/nvim/init.lua"
        "$HOMECONFIG/tmux/tmux.conf:$DOTFILES/config/tmux/tmux.conf"
    )

    for symlink_check in "${critical_symlinks[@]}"; do
        local symlink_path="${symlink_check%:*}"
        local expected_target="${symlink_check#*:}"

        if [[ -e "$expected_target" ]]; then
            if is_symlink_correct "$symlink_path" "$expected_target"; then
                echo "✅ $symlink_path → $expected_target"
            else
                echo "❌ $symlink_path is not correctly linked to $expected_target"
                verification_failed=true
            fi
        fi
    done

    if [[ "$verification_failed" == "true" ]]; then
        echo "⚠️  Some symlinks verification failed"
        return 1
    else
        echo "✅ All critical symlinks verified successfully"
        return 0
    fi
}

# Main execution
main() {
    local action="${1:-create}"

    case "$action" in
    "create")
        create_dotfiles_symlinks
        ;;
    "verify")
        verify_symlinks
        ;;
    "clean")
        echo "🧹 Cleaning broken symlinks..."
        remove_broken_symlinks "$HOME"
        remove_broken_symlinks "$HOMECONFIG"
        echo "✅ Cleanup completed"
        ;;
    *)
        echo "Usage: $0 [create|verify|clean]" >&2
        echo "  create - Create all dotfiles symlinks (default)" >&2
        echo "  verify - Verify critical symlinks are correct" >&2
        echo "  clean  - Remove broken symlinks only" >&2
        exit 1
        ;;
    esac
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
