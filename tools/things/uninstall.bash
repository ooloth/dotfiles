#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

bin_dir="$(go env GOBIN)"
if [[ -z "${bin_dir}" ]]; then
  bin_dir="$(go env GOPATH)/bin"
fi

info "✅ Uninstalling things-cli"
rm -f "${bin_dir}/things"
