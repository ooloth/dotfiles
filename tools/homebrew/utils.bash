#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="homebrew"
export TOOL_UPPER="Homebrew"
export TOOL_COMMAND="brew"
export TOOL_PACKAGE="brew"
export TOOL_EMOJI="🍺"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix="${TOOL_UPPER} "

  # Everything after the prefix
  printf "${raw_version#"${prefix}"}"
}

BREW_LAST_UPDATE_TIME_FILE="${TMPDIR:-/tmp}/.brew_last_update"
BREW_OUTDATED_LIST_CACHE_FILE="${TMPDIR:-/tmp}/.brew_outdated_list"

# Check if a Homebrew formula is installed
#
# Usage: is_brew_formula_installed "package-name"
# Returns: 0 if installed, 1 if not installed
is_brew_formula_installed() {
  local formula="$1"

  if [[ -z "$formula" ]]; then
    echo "Error: Package name required" >&2
    return 1
  fi

  if ! brew list --formula "$formula" &>/dev/null; then
    return 1
  fi

  return 0
}

ensure_brew_formula_installed() {
  local formula="${1}"

  if ! is_brew_formula_installed "${formula}"; then
    debug "🍺 Installing ${formula}"
    brew install --formula "${formula}"
  else
    printf "✅ ${formula} is already installed\n"
  fi
}

# Get the number of seconds since the last brew update
# Returns: seconds since last update, or a large number if not found
get_seconds_since_last_brew_update() {
  [[ ! -f "${BREW_LAST_UPDATE_TIME_FILE}" ]] && echo "999999" && return

  local current_time_sec=$(date +%s)
  local last_update_sec=$(cat "${BREW_LAST_UPDATE_TIME_FILE}" 2>/dev/null || echo "0")
  local update_age_sec=$((current_time_sec - last_update_sec))

  printf "$update_age_sec"
}

# Populate the cached list of outdated brew formulae, one package name per line
# Called each time brew update is run
cache_brew_outdated_formula_list() {
  printf "🍺 Refreshing cached outdated brew formulae\n"
  brew outdated --formula --json=v2 | jq -r '.formulae[].name' >"${BREW_OUTDATED_LIST_CACHE_FILE}" || return 1

}

# Ensure brew update has been run recently.
#
# Returns: 0 if update is recent or was run, 1 if update failed
ensure_brew_recently_updated() {
  local age_limit_hrs=24
  local age_limit_sec=86400

  if get_seconds_since_last_brew_update -lt $age_limit_sec; then
    return 0 # Update is recent enough
  fi

  # Run brew update and cache timestamp + outdated list
  debug "🍺 Running brew update (last update was > ${age_limit_hrs}h ago)" >&2
  if brew update >/dev/null 2>&1; then
    local current_time_sec=$(date +%s)
    printf "$current_time_sec" >"${BREW_LAST_UPDATE_TIME_FILE}"
    cache_brew_outdated_formula_list
    return 0
  else
    echo "⚠️ Warning: brew update failed" >&2
    return 1
  fi
}

# Get the cached list of outdated formulae, creating it if needed
get_brew_outdated_formula_list() {
  if [[ ! -f "${NPM_OUTDATED_LIST_CACHE_FILE}" ]]; then
    # If the cache file doesn't exist, create it
    ensure_brew_recently_updated | return 1
  else
    # Check the age of the cache file
    local current_time_sec=$(date +%s)
    local last_modified_sec=$(stat -f %m "${NPM_OUTDATED_LIST_CACHE_FILE}")
    local cache_age_sec=$((current_time_sec - last_modified_sec))
    local age_limit_sec=86400

    # If the cache file is older than the age limit, refresh it
    if ((cache_age_sec > age_limit_sec)); then
      cache_brew_outdated_formula_list || return 1
    fi
  fi

  # Return the contents of the cached outdated list
  cat "${BREW_OUTDATED_LIST_CACHE_FILE}" 2>/dev/null || return 1
}

# Check if a formula is outdated (needs updating)
#
# Usage: is_formula_outdated "package-name"
# Returns: 0 if outdated, 1 if up-to-date or not installed
is_brew_formula_outdated() {
  local formula="${1}"

  # If formula appears in outdated list, it needs updating
  if get_brew_outdated_formula_list | grep -Fxq "$formula"; then
    return 0 # Outdated
  else
    return 1 # Up-to-date or not installed
  fi
}

ensure_brew_formula_updated() {
  local formula="${1}"

  if ! is_brew_formula_installed "${formula}"; then
    debug "🍺 Installing ${formula}"
    brew install --formula "${formula}"
  else
    if is_brew_formula_outdated "${formula}"; then
      info "🍺 Updating ${formula}"
      brew upgrade --formula "${formula}"
    else
      printf "✅ ${formula} is already up-to-date\n"
    fi
  fi
}
