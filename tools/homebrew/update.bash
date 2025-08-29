#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/homebrew/utils.bash" # source last to avoid env var overrides

# Update brew + remove old versions + remove old downloads
update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew update" \
  "${TOOL_COMMAND} --version" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash"

debug "${TOOL_EMOJI} Caching updated list of outdated formulae"
cache_brew_outdated_formula_list

printf "${TOOL_EMOJI} Removing orphaned subdependencies\n"
brew autoremove

printf "${TOOL_EMOJI} Removing old downloads\n"
brew cleanup --quiet
