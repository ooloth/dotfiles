#!/usr/bin/env bash
set -euo pipefail

parse_version() {
  # Drop the prefix
  local raw_version="$1"
  printf "${raw_version#saul.pw/VisiData v}"
}
