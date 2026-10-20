#!/usr/bin/env bash
# Runs every check this repo has, fastest first, and stops at the first category that fails.
# CI runs the same scripts in the same order, one step each (.github/workflows/check.yml).
# Each runs under /bin/bash, macOS's own bash 3.2, because that is the `bash` CI has. A newer
# Homebrew bash first on PATH would otherwise let a script that needs bash 4 pass here and fail there.
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

run "formatting" /bin/bash "${checks}/formatting.bash"
run "docs" uv run "${checks}/docs.py"
run "types" /bin/bash "${checks}/types.bash"
run "linting" /bin/bash "${checks}/linting.bash"
run "tests" /bin/bash "${checks}/tests.bash"

printf '\n✅ All checks passed\n'
