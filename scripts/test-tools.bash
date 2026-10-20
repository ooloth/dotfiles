#!/usr/bin/env bash
# Runs every tests/test_*.py in a tool or feature folder, with uv so its inline dependencies install.
# Fails if it finds no tests, or a test_*.py at a tool's or feature's root, which it would never run.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
folders=("${repo}/tools" "${repo}/features")

mapfile -t stray < <(find "${folders[@]}" -mindepth 2 -maxdepth 2 -name 'test_*.py' | sort)
if [[ ${#stray[@]} -gt 0 ]]; then
  printf '❌ Tests belong in {tool or feature}/tests/, so these would never run:\n' >&2
  printf '  %s\n' "${stray[@]#"${repo}/"}" >&2
  exit 1
fi

mapfile -t tests < <(
  find "${folders[@]}" -mindepth 3 -maxdepth 3 -path '*/tests/test_*.py' \
    ! -path '*/@new/*' ! -path '*/@archive/*' | sort
)
if [[ ${#tests[@]} -eq 0 ]]; then
  printf '❌ No tests found in tools/*/tests/ or features/*/tests/\n' >&2
  exit 1
fi

failed=()
for test in "${tests[@]}"; do
  printf '\n== %s\n' "${test#"${repo}/"}"
  uv run "${test}" || failed+=("${test#"${repo}/"}")
done

if [[ ${#failed[@]} -gt 0 ]]; then
  printf '\n❌ Failed:\n' >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi

printf '\n✅ All %d test files passed\n' "${#tests[@]}"
