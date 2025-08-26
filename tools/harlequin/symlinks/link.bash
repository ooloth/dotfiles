#!/usr/bin/env bash
set -euo pipefail

if [ "${VERBOSE:-false}" = true ]; then
  printf "✅ No configuration files to symlink\n"
fi
