#!/usr/bin/env bash
# Runs every tool's tests: each tools/{tool}/tests/test_*.py, with uv so its inline dependencies install.
# Fails if it finds no tests, or a test_*.py at a tool's root, which this would otherwise never run.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mapfile -t stray < <(find "${repo}/tools" -mindepth 2 -maxdepth 2 -name 'test_*.py' | sort)
if [[ ${#stray[@]} -gt 0 ]]; then
  printf '❌ Tool tests belong in tools/{tool}/tests/, so these would never run:\n' >&2
  printf '  %s\n' "${stray[@]#"${repo}/"}" >&2
  exit 1
fi

mapfile -t tests < <(
  find "${repo}/tools" -mindepth 3 -maxdepth 3 -path '*/tests/test_*.py' \
    ! -path '*/@new/*' ! -path '*/@archive/*' | sort
)
if [[ ${#tests[@]} -eq 0 ]]; then
  printf '❌ No tests found in tools/*/tests/\n' >&2
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

printf '\n✅ All %d tool test files passed\n' "${#tests[@]}"
