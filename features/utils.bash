#!/usr/bin/env bash
set -euo pipefail

get_tool_version() {
  local version_command="${1}"
  local parse_function="${2}"

  local version_raw="$(eval "${version_command}")"

  # Use the optional version parsing function if provided, otherwise return raw version
  if [[ -n "${parse_function}" ]]; then
    "${parse_function}" "${version_raw}"
  else
    printf "${version_raw}"
  fi
}
