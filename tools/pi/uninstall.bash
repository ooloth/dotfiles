#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

info "🥧 Uninstalling Pi"
npm uninstall --global @earendil-works/pi-coding-agent
