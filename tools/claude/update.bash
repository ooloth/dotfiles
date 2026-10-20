#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

cask="claude-code@latest"
package="lib/node_modules/@anthropic-ai/claude-code"

# An unset variable would make the scan skip a whole set of npm copies without anyone noticing
for var in FNM_DIR HOMEBREW_PREFIX; do
  if [[ -z "${!var:-}" ]]; then
    error "❌ ${var} is not set, so npm copies of Claude Code can't be found"
    exit 1
  fi
done

# Deleted directly rather than with npm, so the cleanup doesn't depend on any Node or npm working
remove_npm_copy() {
  local install="$1"
  local link="${install}/bin/claude"

  if ! rm -rf "${install:?}/${package}" || [[ -e "${install}/${package}" ]]; then
    error "❌ Could not remove the npm copy of Claude Code from ${install}"
    return 1
  fi

  # Only the link npm made for this package goes; a claude link pointing anywhere else stays
  if [[ -L "${link}" && "$(readlink "${link}")" == *"${package}/"* ]]; then
    rm "${link}"
  fi

  warn "⚠️ Removed the npm copy of Claude Code from ${install}"
}

# Every claude on PATH must be the cask's, or some directories run a different version
check_claude_on_path() {
  local caskroom="${HOMEBREW_PREFIX}/Caskroom/${cask}/"
  local found=false
  local foreign=()
  local claude resolved

  while IFS= read -r claude; do
    found=true
    resolved="$(realpath "${claude}")"
    if [[ "${resolved}" != "${caskroom}"* ]]; then
      foreign+=("${claude} → ${resolved}")
    fi
  done < <(type -aP claude)

  if [[ "${found}" == false ]]; then
    error "❌ No claude is on PATH after installing the ${cask} cask"
    return 1
  fi

  if [[ ${#foreign[@]} -gt 0 ]]; then
    error "❌ A claude on PATH is not the ${cask} cask's"
    printf "  - %s\n" "${foreign[@]}" >&2
    return 1
  fi
}

info "🤖 Updating Claude Code"

for install in "${HOMEBREW_PREFIX}" "${FNM_DIR}"/node-versions/*/installation; do
  if [[ -d "${install}/${package}" ]]; then
    remove_npm_copy "${install}"
  fi
done

# Runs before the Homebrew step on purpose: the cask can't link over an npm copy's bin/claude.
# Once every machine has migrated, homebrew's `brew upgrade` (or Claude Code itself) updates it.
if ! brew list --cask "${cask}" &>/dev/null; then
  debug "🍺 Installing the ${cask} cask"
  brew install --cask "${cask}"
fi

check_claude_on_path

debug "🤖 Adding user-scoped MCP servers (requires OAuth on first use)"
claude mcp add --transport http --scope user notion https://mcp.notion.com/mcp 2>/dev/null || true
