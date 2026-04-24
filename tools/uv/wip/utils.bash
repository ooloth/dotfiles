#!/usr/bin/env bash

# UV utilities for dotfiles setup


# Check if UV is installed
is_uv_installed() {
    command -v uv >/dev/null 2>&1
}

# Get UV version
get_uv_version() {
    if is_uv_installed; then
        uv --version 2>/dev/null || echo "unknown"
    else
        echo "not installed"
    fi
}

# Install UV using Homebrew
install_uv() {
    if command -v brew >/dev/null 2>&1; then
        echo "📦 Installing UV..."
        if brew install uv; then
            echo "✅ UV installed successfully"
            return 0
        else
            echo "❌ Failed to install UV" >&2
            return 1
        fi
    else
        echo "❌ Homebrew not found. Please install Homebrew first." >&2
        return 1
    fi
}