#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="gcloud"
export TOOL_UPPER="Google Cloud SDK"
export TOOL_COMMAND="gcloud"
export TOOL_PACKAGE="gcloud"
export TOOL_EMOJI="☁️"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix="${TOOL_UPPER} "

  # Everything after the prefix
  printf "${raw_version#"${prefix}"}"
}
