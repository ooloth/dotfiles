#!/usr/bin/env bash
# Runs every test, and fails after running them all if any failed.
#
# Run with: bash scripts/checks/tests.bash [path...]
#
# Given paths, such as one test file, it runs only those with pytest, with the same dependencies
# installed, and skips the link.bash check.
#
# - link.bash scripts: scripts/checks/link-scripts.bash, alongside the pytest run below, with its
#   output printed after.
# - every test, in one pytest run spread across the machine's cores by pytest-xdist: pytest collects
#   every test_*.py at any depth under tools/, features/ and scripts/, which takes in the shared
#   skills' tests, but only each tests/test_*.py one folder down, such as tools/<tool>/tests/, has
#   its inline header installed. Finding no tests/test_*.py fails, and so does a test_*.py one
#   folder down without a tests/ folder, such as tools/<tool>/test_x.py, which breaks the layout in
#   decision 001. pytest exits 5 when it collects nothing. importlib mode keeps same-named test files, such as the two
#   tests/test_update.py, from colliding on import.
#
# pytest ignores each file's inline script header, so uv installs each tests/test_*.py file's header
# with --with-requirements (decision 001's addendum), and a file with no header fails the run. The
# skill tests have no headers; hypothesis and pydantic are installed for them, since they load their
# scripts in-process or run them as a subprocess, and generate inputs for them. markdown-it-py is
# installed because use-jira's check imports it and its tests run it under this Python; its range
# matches the script's own header, which a test compares. youtube-transcript-api is installed for
# use-youtube's transcript.py on the same terms. pydantic and truststore are pinned to the exact
# versions use-jira's fetch_jira_backlog.py pins, which a test compares, and the other skill scripts'
# pydantic ranges allow that version.
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

with=(--with pytest --with pytest-xdist --with hypothesis --with 'markdown-it-py>=4,<5'
  --with 'youtube-transcript-api>=1,<2' --with 'truststore==0.10.5' --with 'pydantic==2.14.3')
for test in "${tests[@]}"; do
  with+=(--with-requirements "${test}")
done

failed=()

if [[ $# -gt 0 ]]; then
  targets=()
  for path in "$@"; do
    targets+=("$(cd "$(dirname "${path}")" && pwd)/$(basename "${path}")")
  done
else
  targets=(tools features scripts)
  logs="$(mktemp -d)"
  bash "${repo}/scripts/checks/link-scripts.bash" >"${logs}/link-scripts" 2>&1 &
  link_pid=$!
  trap 'kill "${link_pid}" 2>/dev/null; rm -rf "${logs}"' EXIT
fi

printf '\n== pytest\n'
(cd "${repo}" && uv run --quiet "${with[@]}" pytest --import-mode=importlib -q -n auto \
  --dist worksteal --durations=10 -o 'norecursedirs=@archive @new .* __pycache__ node_modules' \
  "${targets[@]}") || failed+=("pytest")

if [[ $# -eq 0 ]]; then
  wait "${link_pid}" || failed+=("scripts/checks/link-scripts.bash")
  printf '\n== scripts/checks/link-scripts.bash\n'
  cat "${logs}/link-scripts"
fi

if [[ ${#failed[@]} -gt 0 ]]; then
  printf '\n❌ Failed:\n' >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi

printf '\n✅ All tests passed\n'
