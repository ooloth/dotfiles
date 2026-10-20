#!/usr/bin/env bash
# Checks that every file a formatter covers is already formatted.
#
# Run with: bash scripts/checks/formatting.bash
#
# Python: ruff format, with rules from ruff.toml at the root. ruff discovers ruff.toml itself
# rather than being handed it, because --config resolves the archive exclude against the working
# directory and would check the archive from anywhere but the root. ruff exits 0 when it finds no
# Python files, so this fails first if there are none.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${DOTFILES}/scripts/checks/versions.bash"
cd "${DOTFILES}"

if [[ -z "$(find . -name '*.py' -not -path '*/__pycache__/*' -print -quit)" ]]; then
  echo "No Python files found, so nothing would be checked." >&2
  exit 1
fi

echo "== ruff format --check"
uv run --quiet --with "ruff==${RUFF_VERSION}" ruff format --check .
