#!/usr/bin/env bash
# Intentionally omitting -e: a failing step must not block the steps that don't depend on it
set -uo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

failed_steps=()

# Runs a step and records its label if it fails, so later steps still run
run_step() {
  local label="$1"
  shift
  "$@" || failed_steps+=("$label")
}

trust_all_taps() {
  local taps
  mapfile -t taps < <(brew tap)
  brew trust --taps "${taps[@]}"
}

info "🍺 Updating homebrew"

debug "📦 Regenerating combined Brewfile"
if bash "${DOTFILES}/tools/homebrew/generate-brewfile.bash"; then
  brewfile_generated=true
else
  failed_steps+=("generate Brewfile")
  brewfile_generated=false
fi

debug "🍺 Refreshing formula database"
run_step "brew update" brew update

debug "🔓 Trusting all tapped third-party sources"
run_step "brew trust" trust_all_taps

# Bundle is the only step that depends on another: without a fresh Brewfile there is nothing valid to install
if [[ "$brewfile_generated" == true ]]; then
  debug "📦 Ensuring all declared packages are installed"
  run_step "brew bundle" brew bundle --file="${DOTFILES}/tools/homebrew/Brewfile.generated"
else
  failed_steps+=("brew bundle (skipped: Brewfile not generated)")
fi

debug "📦 Upgrading all installed packages"
run_step "brew upgrade" brew upgrade

debug "🍺 Removing orphaned subdependencies"
run_step "brew autoremove" brew autoremove

debug "🍺 Removing old downloads"
run_step "brew cleanup" brew cleanup --quiet

if [[ ${#failed_steps[@]} -gt 0 ]]; then
  error "❌ Some Homebrew steps failed"
  printf "  - %s\n" "${failed_steps[@]}" >&2
  printf "\n" >&2
  exit 1
fi

debug "🚀 All Homebrew packages are up to date"
