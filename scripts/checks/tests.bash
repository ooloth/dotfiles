#!/usr/bin/env bash
# Runs every test, and fails after running them all if any failed.
#
# Run with: bash scripts/checks/tests.bash
#
# - link.bash scripts: scripts/checks/link-scripts.bash
# - every tests/test_*.py in a folder under tools/, features/ or scripts/, each with `uv run` so its
#   inline dependencies install. Finding none fails, and so does a test_*.py placed directly in such
#   a folder, which this would never run.
# - the shared skills' tests, with pytest, which finds test_*.py at any depth under
#   tools/agents/config/skills/ and exits 5 when it collects nothing. importlib mode keeps two
#   skills' same-named test files from colliding on import.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
folders=("${repo}/tools" "${repo}/features" "${repo}/scripts")

mapfile -t stray < <(find "${folders[@]}" -mindepth 2 -maxdepth 2 -name 'test_*.py' | sort)
if [[ ${#stray[@]} -gt 0 ]]; then
  printf '❌ Tests belong in a tests/ folder beside the code they test, so these would never run:\n' >&2
  printf '  %s\n' "${stray[@]#"${repo}/"}" >&2
  exit 1
fi

mapfile -t tests < <(
  find "${folders[@]}" -mindepth 3 -maxdepth 3 -path '*/tests/test_*.py' \
    ! -path '*/@new/*' ! -path '*/@archive/*' | sort
)
if [[ ${#tests[@]} -eq 0 ]]; then
  printf '❌ No tests found in tools/*/tests/, features/*/tests/ or scripts/*/tests/\n' >&2
  exit 1
fi

failed=()

printf '\n== scripts/checks/link-scripts.bash\n'
bash "${repo}/scripts/checks/link-scripts.bash" || failed+=("scripts/checks/link-scripts.bash")

for test in "${tests[@]}"; do
  printf '\n== %s\n' "${test#"${repo}/"}"
  uv run "${test}" || failed+=("${test#"${repo}/"}")
done

printf '\n== skill tests\n'
(cd "${repo}" && uv run --with pytest pytest --import-mode=importlib -q tools/agents/config/skills) ||
  failed+=("skill tests")

if [[ ${#failed[@]} -gt 0 ]]; then
  printf '\n❌ Failed:\n' >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi

printf '\n✅ All tests passed\n'
