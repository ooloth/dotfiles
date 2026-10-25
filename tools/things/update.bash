#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# Pinned because things-cli reads the whole Things database, including its URL auth token. Bump it
# only after reading the release's changes, and update tools/agents/config/skills/use-things to
# match any command that changed.
version="v0.11.0"

bin_dir="$(go env GOBIN)"
if [[ -z "${bin_dir}" ]]; then
  bin_dir="$(go env GOPATH)/bin"
fi

# A `go install` build reports "dev" for `things --version`, so read the module version Go embeds
installed_version() {
  go version -m "${bin_dir}/things" 2>/dev/null | awk '$1 == "mod" { print $3 }'
}

info "✅ Updating things-cli"

if [[ "$(installed_version)" == "${version}" ]]; then
  debug "things-cli is already ${version}"
  exit 0
fi

go install "github.com/ryanlewis/things-cli/cmd/things@${version}"

found="$(installed_version)"
if [[ "${found}" != "${version}" ]]; then
  error "things-cli should be ${version} after go install, but ${bin_dir}/things is '${found}'"
  exit 1
fi

debug "installed things-cli ${version}"
