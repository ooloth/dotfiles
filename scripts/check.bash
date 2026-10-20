#!/usr/bin/env bash
# Runs every check this repo has, fastest first, and stops at the first category that fails.
# CI runs the same scripts in the same order, one step each (.github/workflows/check.yml).
#
# Run with: bash scripts/check.bash, or `check` from the repo root
set -uo pipefail

checks="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/checks"

run() {
  printf '\n### %s\n' "$1"
  "${@:2}" || {
    printf '\n❌ %s failed, so the checks after it did not run\n' "$1" >&2
    exit 1
  }
}

run "formatting" bash "${checks}/formatting.bash"
run "docs" uv run "${checks}/docs.py"
run "types" bash "${checks}/types.bash"
run "linting" bash "${checks}/linting.bash"
run "tests" bash "${checks}/tests.bash"

printf '\n✅ All checks passed\n'
