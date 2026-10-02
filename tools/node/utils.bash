#!/usr/bin/env bash

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

# Print the newest LTS Node version (e.g. "v24.21.0")
#
# The default Node tracks LTS rather than the newest release because odd-numbered
# lines (23, 25, ...) reach end-of-life within months and npm drops support for
# them, which breaks `npm install --global npm@latest`. LTS lines last ~30 months.
#
# Usage: latest_lts_node_version
# Returns 1 if fnm can't list remote versions
latest_lts_node_version() {
  local version
  # fnm prints LTS lines with their codename, e.g. "v24.21.0 (Krypton)"
  version="$(fnm ls-remote --lts | tail -n 1 | awk '{print $1}')"

  if [[ ! "${version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf "❌ Could not determine the latest LTS Node version (got '%s')\n" "${version}" >&2
    return 1
  fi

  printf "%s\n" "${version}"
}

# Print the npm version to install for the active Node: "latest" when npm@latest
# supports it, otherwise the newest npm release whose engines.node range does
#
# Usage: npm_version_supporting_active_node
# Returns 1 if the active Node version or npm's supported Node ranges can't be read
npm_version_supporting_active_node() {
  local node_version
  node_version="$(node --version)"
  if [[ ! "${node_version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf "❌ Could not read the active Node version (got '%s')\n" "${node_version}" >&2
    return 1
  fi

  # The active npm bundles semver, so range checks need no extra dependency
  local semver_module
  semver_module="$(npm root --global)/npm/node_modules/semver"
  if [[ ! -d "${semver_module}" ]]; then
    printf "❌ Could not find npm's bundled semver module at %s\n" "${semver_module}" >&2
    return 1
  fi

  local latest_node_range
  latest_node_range="$(npm view npm@latest engines.node)"
  if [[ -z "${latest_node_range}" ]]; then
    printf "❌ Could not read the Node versions npm@latest supports\n" >&2
    return 1
  fi

  if node -e 'process.exit(require(process.argv[1]).satisfies(process.version, process.argv[2]) ? 0 : 1)' \
    "${semver_module}" "${latest_node_range}"; then
    printf "latest\n"
    return 0
  fi

  local newest_supported_version
  newest_supported_version="$(
    npm view "npm@>=1" version engines.node --json | node -e '
      const semver = require(process.argv[1]);
      const releases = [].concat(JSON.parse(require("fs").readFileSync(0, "utf8")));
      const supported = releases
        .filter((release) => release["engines.node"] && semver.satisfies(process.version, release["engines.node"]))
        .map((release) => release.version);
      const newest = semver.maxSatisfying(supported, "*");
      if (newest) console.log(newest);
    ' "${semver_module}"
  )"
  if [[ -z "${newest_supported_version}" ]]; then
    printf "❌ No npm release supports Node %s\n" "${node_version}" >&2
    return 1
  fi

  printf "%s\n" "${newest_supported_version}"
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
