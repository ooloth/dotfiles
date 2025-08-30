#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="node"
export TOOL_UPPER="Node"
export TOOL_COMMAND="node"
export TOOL_PACKAGE="node"
export TOOL_EMOJI="🟢"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix="v"

  # Everything after the prefix
  printf "${raw_version#"${prefix}"}"

}

NPM_OUTDATED_LIST_CACHE_FILE="${TMPDIR:-/tmp}/.npm_outdated_list"

# Check if a global npm package is installed
#
# Usage: is_global_npm_package_installed <package-name>
# Returns 0 if installed, 1 otherwise
is_global_npm_package_installed() {
  local package="${1}"

  if [[ -z "${package}" ]]; then
    echo "Error: Package name required" >&2
    return 1
  fi

  if ! npm list --global --json 2>/dev/null | jq -e ".dependencies | has(\"${package}\")" &>/dev/null; then
    return 1
  fi

  return 0
}

# Check if a global npm package is installed, and install it if not
# See: https://docs.npmjs.com/cli/v9/commands/npm-update?v=true#updating-globally-installed-packages
#
# Usage: ensure_global_npm_package_installed <package-name>
# Returns 0 if installed or successfully installed, 1 on error
ensure_global_npm_package_installed() {
  local package="${1}"

  if ! is_global_npm_package_installed "${package}"; then
    debug "📦 Installing ${package}"
    npm install --global "${package}" || return 1
  else
    printf "✅ ${package} is already installed\n"
  fi
}

# Populate the cached list of outdated global npm packages, one package name per line
# Called each time brew update is run
cache_global_npm_outdated_list() {
  printf "📦 Refreshing cached outdated global npm packages\n"
  npm outdated --global --json | jq -r 'keys[]' >"${NPM_OUTDATED_LIST_CACHE_FILE}" || return 1
}

# Get the cached list of outdated global npm packages
# Refreshes the cache if it's missing or more than 24 hours old
#
# Usage: get_global_npm_outdated_list
# Returns the JSON list of outdated packages, or nothing if none are outdated
get_global_npm_outdated_list() {
  if [[ ! -f "${NPM_OUTDATED_LIST_CACHE_FILE}" ]]; then
    # If the cache file doesn't exist, create it
    cache_global_npm_outdated_list || return 1
  else
    # Check the age of the cache file
    local current_time_sec=$(date +%s)
    local last_modified_sec=$(stat -f %m "${NPM_OUTDATED_LIST_CACHE_FILE}")
    local cache_age_sec=$((current_time_sec - last_modified_sec))
    local age_limit_sec=86400

    # If the cache file is older than the age limit, refresh it
    if ((cache_age_sec > age_limit_sec)); then
      cache_global_npm_outdated_list || return 1
    fi
  fi

  # Return the contents of the cached outdated list
  cat "${NPM_OUTDATED_LIST_CACHE_FILE}" 2>/dev/null || return 1
}

# Check if a global npm package is outdated by comparing against the cached outdated list
#
# Usage: is_global_npm_package_outdated <package-name>
# Returns 0 if outdated, 1 if up-to-date or not installed
is_global_npm_package_outdated() {
  local package="${1}"

  # If package appears in the outdated list, it needs updating
  if get_global_npm_outdated_list | grep -Fxq "$package"; then
    return 0 # Outdated
  else
    return 1 # Up-to-date or not installed
  fi
}

# Check if a global npm package is up-to-date, installing or updating it as needed
#
# Usage: ensure_global_npm_package_updated <package-name>
# Returns 0 if up-to-date or successfully installed/updated, 1 on error
ensure_global_npm_package_updated() {
  local package="${1}"

  if ! is_global_npm_package_installed "${package}"; then
    debug "📦 Installing ${package}"
    npm install -g "${package}@latest"
  else
    if is_global_npm_package_outdated "${package}"; then
      debug "📦 Updating ${package}"
      npm install -g "${package}@latest"
    else
      printf "✅ ${package} is already up-to-date\n"
    fi
  fi
}
