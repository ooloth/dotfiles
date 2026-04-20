#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🍺 Installing Homebrew"
# Run as login shell so the script doesn't pause for user input
# Use arch -arm64 to ensure Apple Silicon version: https://github.com/orgs/Homebrew/discussions/417#discussioncomment-2684303
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | arch -arm64 /bin/bash --login
