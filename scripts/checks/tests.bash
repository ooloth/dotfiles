#!/usr/bin/env bash
# Runs every test, and fails after running them all if any failed.
#
# Run with: bash scripts/checks/tests.bash
#
# - link.bash scripts: scripts/checks/link-scripts.bash, alongside the pytest run below, with its
#   output printed after.
# - every test, in one pytest run spread across the machine's cores by pytest-xdist: each
#   tests/test_*.py in a folder under tools/, features/ or scripts/, and the shared skills' tests at
#   any depth under tools/agents/config/skills/. Finding no tests/test_*.py fails, and so does a
#   test_*.py placed directly in such a folder, which breaks the layout in decision 001. pytest exits
#   5 when it collects nothing. importlib mode keeps same-named test files, such as the two
#   tests/test_update.py, from colliding on import.
#
# pytest ignores each file's inline script header, so scripts/checks/test-dependencies.py reads the
# headers and each package it prints is installed alongside (decision 001's addendum). The skill
# tests have no headers; hypothesis and pydantic are installed for them, since they load their
# scripts in-process and generate inputs for them.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
folders=("${repo}/tools" "${repo}/features" "${repo}/scripts")

# while-read rather than mapfile, which macOS's own bash 3.2, the one CI runs, does not have
stray=()
while IFS= read -r file; do
  stray+=("${file}")
done < <(find "${folders[@]}" -mindepth 2 -maxdepth 2 -name 'test_*.py' | sort)
if [[ ${#stray[@]} -gt 0 ]]; then
  printf '❌ Tests belong in a tests/ folder beside the code they test:\n' >&2
  printf '  %s\n' "${stray[@]#"${repo}/"}" >&2
  exit 1
fi

tests=()
while IFS= read -r file; do
  tests+=("${file}")
done < <(
  find "${folders[@]}" -mindepth 3 -maxdepth 3 -path '*/tests/test_*.py' \
    ! -path '*/@new/*' ! -path '*/@archive/*' | sort
)
if [[ ${#tests[@]} -eq 0 ]]; then
  printf '❌ No tests found in tools/*/tests/, features/*/tests/ or scripts/*/tests/\n' >&2
  exit 1
fi

if ! declared="$(uv run --quiet "${repo}/scripts/checks/test-dependencies.py" "${tests[@]}")"; then
  printf '❌ Could not read the test files'"'"' dependencies\n' >&2
  exit 1
fi
with=(--with pytest --with pytest-xdist --with hypothesis --with pydantic)
while IFS= read -r package; do
  [[ -n "${package}" ]] && with+=(--with "${package}")
done <<<"${declared}"

failed=()

logs="$(mktemp -d)"
bash "${repo}/scripts/checks/link-scripts.bash" >"${logs}/link-scripts" 2>&1 &
link_pid=$!
trap 'kill "${link_pid}" 2>/dev/null; rm -rf "${logs}"' EXIT

printf '\n== pytest\n'
(cd "${repo}" && uv run --quiet "${with[@]}" pytest --import-mode=importlib -q -n auto \
  --dist worksteal --durations=10 -o 'norecursedirs=@archive @new .* __pycache__ node_modules' \
  tools features scripts) || failed+=("pytest")

wait "${link_pid}" || failed+=("scripts/checks/link-scripts.bash")
printf '\n== scripts/checks/link-scripts.bash\n'
cat "${logs}/link-scripts"

if [[ ${#failed[@]} -gt 0 ]]; then
  printf '\n❌ Failed:\n' >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi

printf '\n✅ All tests passed\n'
