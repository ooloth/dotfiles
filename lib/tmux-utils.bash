#!/usr/bin/env bash

# Tmux installation utilities
# Provides functions for managing Tmux Plugin Manager (TPM)

set -euo pipefail

# Check if TPM is installed
tpm_installed() {
    local tpm_dir="$HOME/.config/tmux/plugins/tpm"
    [ -d "$tpm_dir" ]
}