#!/usr/bin/env bash
set -euo pipefail

parse_version() {
  # Grab the first line after the prefix
  local raw_version="$1"
  printf "${raw_version#harlequin, version }" | head -n 1
}
