#!/usr/bin/env bash
set -euo pipefail

parse_version() {
  # Grab the second word
  local raw_version="$1"
  printf "$(echo "$raw_version" | awk '{print $2}')"
}
