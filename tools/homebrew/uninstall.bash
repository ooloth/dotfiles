#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# See: https://docs.brew.sh/FAQ#how-do-i-uninstall-homebrew
# See: https://github.com/homebrew/install?tab=readme-ov-file#uninstall-homebrew
info "🍺 Uninstalling Homebrew"
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
