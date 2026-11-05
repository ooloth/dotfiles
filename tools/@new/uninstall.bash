#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

# TODO: add non-brew uninstall steps (e.g. npm/uv/bun uninstalls, trash config dirs)
# TODO: delete this file if there are no non-brew steps (brew handled by #140)
info "TODO: Uninstalling @new"
