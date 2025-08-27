#!/usr/bin/env bash
set -euo pipefail

# NOTE: node vs npm vs fnm...?
export TOOL_LOWER="npm"
export TOOL_UPPER="npm"
export TOOL_COMMAND="npm"
export TOOL_PACKAGE="npm"
export TOOL_EMOJI="📦"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"

  # No edits needed for "npm --version"
  printf "${raw_version}"
}

is_global_npm_package_installed() {
  local package="$1"
  npm list -g --depth=0 2>/dev/null | grep -q " ${package}@"
  return $? # Return the exit status of the grep command
}

ensure_global_npm_package_installed() {
  local package="${1}"

  if ! is_global_npm_package_installed "${package}"; then
    debug "📦 Installing ${package}"
    npm install -g "${package}"
  else
    printf "✅ ${package} is already installed\n"
  fi
}

is_global_npm_package_outdated() {
  local package="${1}"
  npm outdated -g 2>/dev/null | grep -q "^${package}[[:space:]]"
  return $? # Return the exit status of the grep command
}

ensure_global_npm_package_updated() {
  local package="${1}"

  if ! is_global_npm_package_installed "${package}"; then
    info "📦 Installing ${package}"
    npm install -g "${package}"
  else
    if is_global_npm_package_outdated "${package}"; then
      info "📦 Updating ${package}"
      npm install -g "${package}"
    else
      printf "✅ ${package} is already up-to-date\n"
    fi
  fi
}

# WARN: all helpers below are speculative (not used yet)

get_missing_global_npm_packages() {
  local packages=("$@")
  local missing_packages=()

  for package in "${packages[@]}"; do
    if ! is_global_npm_package_installed "$package"; then
      missing_packages+=("$package")
    fi
  done

  printf '%s\n' "${missing_packages[@]}"
}

get_outdated_global_npm_packages() {
  local packages=("$@")
  local outdated_packages=()

  for package in "${packages[@]}"; do
    if is_global_npm_package_outdated "$package"; then
      outdated_packages+=("$package")
    fi
  done

  printf '%s\n' "${outdated_packages[@]}"
}
