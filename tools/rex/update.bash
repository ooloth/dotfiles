#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🦖 Updating rex"
brew bundle --file="${DOTFILES}/tools/rex/Brewfile"

# init.lua starts the session saver with `uv run --offline`, so that a restore at boot never waits
# on the network. Its dependencies must therefore already be in uv's cache, and running it once here
# puts them there.
uv run --quiet --script "${DOTFILES}/tools/rex/saver.py" --help >/dev/null
