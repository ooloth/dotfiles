#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📊 Updating VisiData"
uv tool install --upgrade visidata --with pyarrow
