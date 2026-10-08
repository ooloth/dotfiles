#!/usr/bin/env bash
# Check that every project command (check, test, start, ...) fails when no case matches the current
# directory, and exits with its tool's status when one does.
#
# Run with: bash scripts/check-project-commands.bash
#
# Each features/*/*.bash that dispatches on `current_dir=$(basename ...)` picks what to run from the
# name of the current directory and the machine. These are what the shell aliases `check`, `test`,
# `start` and the rest run. A command that finds no case must exit non-zero, so a caller (an agent,
# a loop, `&&`) cannot mistake "nothing ran" for "it passed".
#
# Every run uses a temporary HOME that links to this checkout, because tools/bash/utils.bash sets
# DOTFILES from HOME, so a run from a worktree would otherwise test the main checkout. `uv` is
# replaced by a stub on PATH, and PATH holds only the system directories besides it.
#
#   T0  after sourcing tools/bash/utils.bash, is_work follows COMPUTER (work: true, air: false)
#   T1  every project command, run in a directory no case matches, exits non-zero
#   T2  in those runs, stderr names the command and directory, and stdout does not
#   T3  check and test in the shared projects exit 0 when uv succeeds, run uv, and print no
#       no-match message
#   T4  check and test in the shared projects exit with uv's status when uv fails
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# `air` stands for every non-work machine, which `mini` shares
MACHINES=(work air)

# A directory name no command has a case for
UNMATCHED_DIR="no-project-command-case"

# The labels of the outer `case` in check.bash and test.bash, which runs before the machine is
# considered. Hard-coded because parsing case labels out of bash would be fragile.
SHARED_PROJECTS=(agency-1 agency-2 agent-1 agent-2)
SHARED_COMMANDS=(check test)

# The exit status the stub uv returns in T4, chosen to be distinguishable from 0 and 1
UV_FAILURE_STATUS=3

scratch="$(mktemp -d)"
trap 'rm -rf "${scratch}"' EXIT

fake_home="${scratch}/home"
mkdir -p "${fake_home}/Repos/ooloth"
ln -s "${REPO}" "${fake_home}/Repos/ooloth/dotfiles"
dotfiles_under_test="${fake_home}/Repos/ooloth/dotfiles"

stub_bin="${scratch}/bin"
mkdir -p "${stub_bin}"
cat >"${stub_bin}/uv" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"${STUB_UV_LOG:?}"
exit "${STUB_UV_EXIT:?}"
EOF
chmod +x "${stub_bin}/uv"

projects_dir="${scratch}/projects"
out="${scratch}/stdout"
err="${scratch}/stderr"
uv_log="${scratch}/uv.log"

passed=0
failed=0

pass() {
  printf "PASS %s\n" "$*"
  passed=$((passed + 1))
}

fail() {
  printf "FAIL %s\n" "$*"
  failed=$((failed + 1))
}

# Prints a captured stream indented under a FAIL line
show() {
  local label="$1" file="$2"
  printf "    %s:\n" "${label}"
  if [[ -s "${file}" ]]; then
    sed 's/^/      | /' "${file}"
  else
    printf "      (empty)\n"
  fi
}

# Run bash the way CI does, wherever this check runs: macOS's own bash (3.2, not a newer Homebrew
# bash) and no terminal, under the fake HOME, the chosen machine, and a PATH where the only tool
# outside the system directories is the stub uv. BASH_ENV is unset so no startup file runs.
#   usage: run_as <machine> <working dir> <uv exit status> <bash args...>
# Writes stdout, stderr and the stub's call log to ${out}, ${err} and ${uv_log}; sets run_status.
run_as() {
  local machine="$1" dir="$2" uv_status="$3"
  shift 3
  : >"${uv_log}"
  (
    cd "${dir}" || exit 99
    env -u TERM -u BASH_ENV \
      HOME="${fake_home}" \
      DOTFILES="${dotfiles_under_test}" \
      COMPUTER="${machine}" \
      PATH="${stub_bin}:/usr/bin:/bin:/usr/sbin:/sbin" \
      STUB_UV_LOG="${uv_log}" \
      STUB_UV_EXIT="${uv_status}" \
      /bin/bash "$@" >"${out}" 2>"${err}"
  )
  run_status=$?
}

no_match_message() {
  local command="$1" dir="$2"
  printf "No '%s' case defined for '/%s'" "${command}" "${dir}"
}

# ─── Setup ──────────────────────────────────────────────────
# Every command must source this checkout's files, not ~/Repos/ooloth/dotfiles. utils.bash
# re-exports DOTFILES from HOME, so check where that lands after sourcing it.

mkdir -p "${projects_dir}/${UNMATCHED_DIR}"
# shellcheck disable=SC2016 # expanded by the child bash, not here
run_as air "${projects_dir}/${UNMATCHED_DIR}" 0 -c \
  'source "${DOTFILES}/tools/bash/utils.bash" && cd "${DOTFILES}" && pwd -P'
resolved="$(cat "${out}")"
if [[ ${run_status} -ne 0 || "${resolved}" != "${REPO}" ]]; then
  printf "SETUP ERROR: sourcing tools/bash/utils.bash under the fake HOME leaves DOTFILES at '%s', not this checkout '%s' (exit %s)\n" \
    "${resolved}" "${REPO}" "${run_status}"
  show stderr "${err}"
  exit 2
fi
printf "Commands source %s\n" "${resolved}"

commands=()
for file in "${REPO}"/features/*/*.bash; do
  grep -qE 'current_dir="?\$\(basename' "${file}" && commands+=("${file#"${REPO}/"}")
done
if [[ ${#commands[@]} -eq 0 ]]; then
  printf "SETUP ERROR: found no features/*/*.bash that dispatches on current_dir=\$(basename ...)\n"
  exit 2
fi
printf "Found %d project commands: %s\n\n" "${#commands[@]}" "${commands[*]}"

# ─── T0: the machine choice takes effect ────────────────────
# T1 passes whichever machine branch runs, so without this the check could not tell whether
# COMPUTER chose the branch.

for machine in "${MACHINES[@]}"; do
  # shellcheck disable=SC2016 # expanded by the child bash, not here
  run_as "${machine}" "${projects_dir}/${UNMATCHED_DIR}" 0 -c \
    'source "${DOTFILES}/tools/bash/utils.bash" && is_work'
  if [[ "${machine}" == "work" ]]; then want=0; else want=1; fi
  if [[ ${run_status} -eq ${want} ]]; then
    pass "T0 is_work machine=${machine}: exit ${run_status}"
  else
    fail "T0 is_work machine=${machine}: exit ${run_status}, want ${want} (COMPUTER=${machine} did not choose the branch)"
    show stderr "${err}"
  fi
done

# ─── T1 + T2: no matching case ──────────────────────────────

for script in "${commands[@]}"; do
  command="$(basename "${script}" .bash)"
  message="$(no_match_message "${command}" "${UNMATCHED_DIR}")"
  for machine in "${MACHINES[@]}"; do
    where="${script} machine=${machine} dir=/${UNMATCHED_DIR}"
    run_as "${machine}" "${projects_dir}/${UNMATCHED_DIR}" 0 "${dotfiles_under_test}/${script}"

    if [[ ${run_status} -ne 0 ]]; then
      pass "T1 ${where}: exit ${run_status}"
    else
      fail "T1 ${where}: exit 0, want non-zero"
    fi

    if grep -qF "${message}" "${err}" && ! grep -qF "${message}" "${out}"; then
      pass "T2 ${where}: stderr names the missing case"
    else
      fail "T2 ${where}: want \"${message}\" on stderr and not on stdout"
      show stdout "${out}"
      show stderr "${err}"
    fi
  done
done

# ─── T3 + T4: a shared project's case matches ───────────────

for project in "${SHARED_PROJECTS[@]}"; do
  mkdir -p "${projects_dir}/${project}"
  for command in "${SHARED_COMMANDS[@]}"; do
    script="features/${command}/${command}.bash"
    message="$(no_match_message "${command}" "${project}")"
    for machine in "${MACHINES[@]}"; do
      where="${script} machine=${machine} dir=/${project}"

      run_as "${machine}" "${projects_dir}/${project}" 0 "${dotfiles_under_test}/${script}"
      problems=()
      [[ ${run_status} -eq 0 ]] || problems+=("exit ${run_status}, want 0")
      [[ -s "${uv_log}" ]] || problems+=("uv was never run")
      if grep -qF "No '${command}' case defined" "${out}" "${err}"; then
        problems+=("printed a no-match message")
      fi
      if [[ ${#problems[@]} -eq 0 ]]; then
        pass "T3 ${where} (uv exits 0): exit 0"
      else
        fail "T3 ${where} (uv exits 0): $(IFS=";"; echo "${problems[*]}")"
        show stderr "${err}"
      fi

      run_as "${machine}" "${projects_dir}/${project}" "${UV_FAILURE_STATUS}" \
        "${dotfiles_under_test}/${script}"
      problems=()
      [[ ${run_status} -eq ${UV_FAILURE_STATUS} ]] ||
        problems+=("exit ${run_status}, want ${UV_FAILURE_STATUS}")
      if grep -qF "No '${command}' case defined" "${out}" "${err}"; then
        problems+=("printed a no-match message")
      fi
      if [[ ${#problems[@]} -eq 0 ]]; then
        pass "T4 ${where} (uv exits ${UV_FAILURE_STATUS}): exit ${run_status}"
      else
        fail "T4 ${where} (uv exits ${UV_FAILURE_STATUS}): $(IFS=";"; echo "${problems[*]}")"
        show stderr "${err}"
      fi
    done
  done
done

printf "\n%d passed, %d failed\n" "${passed}" "${failed}"
[[ ${failed} -eq 0 ]] || exit 1
