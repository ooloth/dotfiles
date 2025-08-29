#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/visidata/utils.bash"

# Includes pyarrow to support opening parquet files
install_and_symlink \
  "${TOOL_UPPER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "uv tool install ${TOOL_PACKAGE} --with pyarrow" \
  "${TOOL_LOWER} --version" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"
