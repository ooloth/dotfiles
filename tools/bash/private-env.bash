# shellcheck shell=bash
# Loads this machine's private values: the PRIVATE_<NAME>=value lines in the ignored private.env at
# the repo root, which hold what must not appear in this public repo. private.env.example lists
# every key.
#
# tools/zsh/config/core.zsh calls load_private_env at startup, and tools/bash/utils.bash calls it
# for a script started outside a configured zsh, such as a Rex tab. Both bash 3.2 and zsh source
# this file.

# Exports every assignment in FILE by sourcing it with allexport on, then turns allexport off so
# nothing the caller assigns later is exported. FILE is shell code that only this machine's owner
# writes. A missing FILE sets nothing and prints nothing.
#
# Usage: load_private_env [FILE]
load_private_env() {
  local file="${1:-${DOTFILES}/private.env}"
  if [[ ! -f "${file}" ]]; then
    return 0
  fi
  set -a
  # shellcheck source=/dev/null
  source "${file}"
  set +a
}
