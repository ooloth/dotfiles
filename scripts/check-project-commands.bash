#!/usr/bin/env bash
# Check that every project command (check, new, run, test, ...) fails when it has no case for the
# current directory, and that its matched shared cases still pass their tool's exit status through.
#
# Run with: bash scripts/check-project-commands.bash
#
# A project command is features/<name>/<name>.bash containing "No '<name>' case defined for". Each
# one picks what to run from the basename of $PWD and, on work machines, a different list of
# directories. When nothing matches it prints that message. Callers such as `check && submit` rely
# on it also exiting 1, on every machine.
#
# For each machine (Air, Mini, Work) this builds a fake HOME holding a copy of the repo whose
# machine detection answers with that machine's name, then runs each command the way CI does:
#   - in an unmatched directory: exit 1, the message on stderr, nothing on stdout
#   - check and test in agency-1 and agent-1 with a stub uv exiting 0: exit 0, uv called, no
#     no-match message
#   - the same with a stub uv exiting 3: exit 3
#
# Exit codes: 0 every run passed, 1 a command or the discovery rule failed, 2 the check's own setup
# failed before any command was judged.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MACHINES=(Air Mini Work)
UNMATCHED_DIR="no-case-matches-this"
SHARED_COMMANDS=(check test)
SHARED_DIRS=(agency-1 agent-1)
FAILING_UV_EXIT=3
# tools/macos/utils.bash calls this by absolute path, so a PATH stub cannot choose the machine
DETECTION_COMMAND="/usr/sbin/networksetup -getcomputername"

setup_failed() {
  printf "🛑 setup failed, no command was judged: %s\n" "$1"
  exit 2
}

scratch="$(mktemp -d)" || setup_failed "could not create a temporary directory"
trap 'rm -rf "${scratch}"' EXIT

###############
# DISCOVERING #
###############

# Only features/<name>/<name>.bash files carrying the no-match message are run. A plain glob would
# also run installers such as a future features/setup/setup.bash. Anything that looks like a
# project command but does not fit that rule is reported rather than skipped silently.
commands=()
discovery_failures=0

for script in "${DOTFILES}"/features/*/*.bash; do
  [[ -f "${script}" ]] || continue
  dir_name="$(basename "$(dirname "${script}")")"
  relative="${script#"${DOTFILES}/"}"

  if [[ "$(basename "${script}")" == "${dir_name}.bash" ]]; then
    if grep -qF "No '${dir_name}' case defined for" "${script}"; then
      commands+=("${dir_name}")
    else
      printf "❌ %s has no \"No '%s' case defined for\" message, so it was not run\n" \
        "${relative}" "${dir_name}"
      discovery_failures=$((discovery_failures + 1))
    fi
  elif grep -qF "case defined for" "${script}"; then
    printf "❌ %s prints a no-match message but is not features/<name>/<name>.bash, so it was not checked\n" \
      "${relative}"
    discovery_failures=$((discovery_failures + 1))
  fi
done

[[ ${#commands[@]} -gt 0 ]] || setup_failed "no project commands found under features/<name>/<name>.bash"
printf "Checking %d project commands: %s\n" "${#commands[@]}" "${commands[*]}"

############
# FIXTURES #
############

stub_bin="${scratch}/bin"
mkdir -p "${stub_bin}" || setup_failed "could not create ${stub_bin}"
cat >"${stub_bin}/uv" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"${STUB_UV_LOG}"
exit "${STUB_UV_EXIT}"
EOF
chmod +x "${stub_bin}/uv" || setup_failed "could not make the stub uv executable"

resolved_uv="$(PATH="${stub_bin}:${PATH}" command -v uv)"
[[ "${resolved_uv}" == "${stub_bin}/uv" ]] ||
  setup_failed "uv resolves to '${resolved_uv}', not the stub at ${stub_bin}/uv"

fake_home() { printf "%s/%s" "${scratch}" "$1"; }
fake_repo() { printf "%s/Repos/ooloth/dotfiles" "$(fake_home "$1")"; }

# tools/bash/utils.bash hard-codes DOTFILES="${HOME}/Repos/ooloth/dotfiles", so the repo goes at
# that path under the fake HOME. It is a copy, not a symlink, so a command run here cannot write
# into the real repo. Only the detection command is replaced: the real `case` and is_* predicates
# still run, so this check cannot drift from how production picks a machine.
build_fixture() {
  local machine="$1"
  local home repo detection_file original
  home="$(fake_home "${machine}")"
  repo="$(fake_repo "${machine}")"
  detection_file="${repo}/tools/macos/utils.bash"
  original="${DOTFILES}/tools/macos/utils.bash"

  mkdir -p "${repo}/tools" || setup_failed "could not create ${repo}/tools"
  local source
  for source in features tools/bash tools/macos; do
    cp -RL "${DOTFILES}/${source}" "${repo}/${source}" ||
      setup_failed "could not copy ${source}/ into the fake repo for ${machine}"
  done

  sed "s|${DETECTION_COMMAND}|echo ${machine}|" "${original}" >"${detection_file}" ||
    setup_failed "could not write ${detection_file}"

  if grep -qF "networksetup" "${detection_file}"; then
    setup_failed "the fake tools/macos/utils.bash for ${machine} still calls networksetup, so it would test the real machine"
  fi
  if ! grep -qF "echo ${machine}" "${detection_file}"; then
    setup_failed "the detection command '${DETECTION_COMMAND}' was not found in tools/macos/utils.bash, so ${machine} could not be faked"
  fi
  local changed_lines
  changed_lines="$(diff "${original}" "${detection_file}" | grep -c '^[<>]')"
  [[ "${changed_lines}" == "2" ]] ||
    setup_failed "faking ${machine} changed more than the one detection line of tools/macos/utils.bash"

  mkdir -p "${home}/${UNMATCHED_DIR}" || setup_failed "could not create ${home}/${UNMATCHED_DIR}"
  local dir
  for dir in "${SHARED_DIRS[@]}"; do
    mkdir -p "${home}/${dir}" || setup_failed "could not create ${home}/${dir}"
  done
}

# An undefined is_work reads as false under `if`, which silently takes the personal branch, so
# this reads COMPUTER, DOTFILES and every predicate back through the same files a command sources.
check_fixture() {
  local machine="$1"
  local home repo expected probe computer
  home="$(fake_home "${machine}")"
  repo="$(fake_repo "${machine}")"
  computer="$(printf "%s" "${machine}" | tr '[:upper:]' '[:lower:]')"
  expected="${repo} ${computer} is_${computer}"

  # shellcheck disable=SC2016 # expanded by the probe's own shell
  probe="$(cd "${home}" && env -u TERM HOME="${home}" DOTFILES="${repo}" /bin/bash -c '
    set -euo pipefail
    source "${DOTFILES}/tools/bash/utils.bash"
    printf "%s %s" "${DOTFILES}" "${COMPUTER}"
    for predicate in is_air is_mini is_work; do
      if "${predicate}"; then printf " %s" "${predicate}"; fi
    done' </dev/null 2>&1)"

  [[ "${probe}" == "${expected}" ]] ||
    setup_failed "$(printf "the fake repo for %s reads back as %q, expected %q" "${machine}" "${probe}" "${expected}")"
}

for machine in "${MACHINES[@]}"; do
  build_fixture "${machine}"
  check_fixture "${machine}"
done

###########
# RUNNING #
###########

# Run a command the way CI does: macOS's own bash 3.2, no terminal, no input, the stub uv first on
# PATH. Sets run_status, run_stdout, run_stderr and run_uv_calls.
run_command() {
  local name="$1" machine="$2" dir="$3" uv_exit="$4"
  local home repo
  home="$(fake_home "${machine}")"
  repo="$(fake_repo "${machine}")"
  : >"${scratch}/uv-calls"

  (cd "${home}/${dir}" &&
    env -u TERM HOME="${home}" DOTFILES="${repo}" PATH="${stub_bin}:${PATH}" \
      STUB_UV_EXIT="${uv_exit}" STUB_UV_LOG="${scratch}/uv-calls" \
      /bin/bash "${repo}/features/${name}/${name}.bash" \
      </dev/null >"${scratch}/stdout" 2>"${scratch}/stderr")
  run_status=$?
  run_stdout="$(cat "${scratch}/stdout")"
  run_stderr="$(cat "${scratch}/stderr")"
  run_uv_calls="$(cat "${scratch}/uv-calls")"
}

runs=0
failed_runs=0
problems=()

# Print one failure for a run with every way it differed, then the captured output with %q so
# newlines and escape codes stay visible.
judge_run() {
  local name="$1" machine="$2" dir="$3" uv_exit="$4"
  runs=$((runs + 1))
  [[ ${#problems[@]} -eq 0 ]] && return

  failed_runs=$((failed_runs + 1))
  printf "❌ %s on %s in /%s with uv exiting %s:\n" "${name}" "${machine}" "${dir}" "${uv_exit}"
  local problem
  for problem in "${problems[@]}"; do
    printf "    - %s\n" "${problem}"
  done
  printf "    exit status: %s\n" "${run_status}"
  # In a UTF-8 locale, bash 3.2's %q escapes only some bytes of each emoji and box character and
  # prints invalid UTF-8; the C locale escapes every non-ASCII byte as octal.
  local LC_ALL=C
  printf "    stdout: %q\n" "${run_stdout}"
  printf "    stderr: %q\n" "${run_stderr}"
  printf "    uv calls: %q\n" "${run_uv_calls}"
}

for machine in "${MACHINES[@]}"; do
  for name in "${commands[@]}"; do
    run_command "${name}" "${machine}" "${UNMATCHED_DIR}" 0
    problems=()
    message="No '${name}' case defined for '/${UNMATCHED_DIR}'"

    # T1: no match exits 1
    [[ "${run_status}" == "1" ]] ||
      problems+=("no match must exit 1, but exited ${run_status}")
    # T2: the message is on stderr
    [[ "${run_stderr}" == *"${message}"* ]] ||
      problems+=("stderr lacks \"${message}\"")
    # T3: nothing on stdout
    [[ -z "${run_stdout}" ]] ||
      problems+=("no match must print nothing on stdout")

    judge_run "${name}" "${machine}" "${UNMATCHED_DIR}" 0
  done

  for name in "${SHARED_COMMANDS[@]}"; do
    for dir in "${SHARED_DIRS[@]}"; do
      # T4: a matched shared case whose tool succeeds exits 0 without the no-match message
      run_command "${name}" "${machine}" "${dir}" 0
      problems=()
      [[ -n "${run_uv_calls}" ]] ||
        problems+=("the matched case never ran uv")
      [[ "${run_status}" == "0" ]] ||
        problems+=("a matched case whose tool succeeds must exit 0, but exited ${run_status}")
      [[ "${run_stderr}" != *"case defined for"* ]] ||
        problems+=("a matched case printed the no-match message")
      judge_run "${name}" "${machine}" "${dir}" 0

      # T5: a matched shared case whose tool fails exits with the tool's status
      run_command "${name}" "${machine}" "${dir}" "${FAILING_UV_EXIT}"
      problems=()
      [[ -n "${run_uv_calls}" ]] ||
        problems+=("the matched case never ran uv")
      [[ "${run_status}" == "${FAILING_UV_EXIT}" ]] ||
        problems+=("a matched case must pass its tool's exit ${FAILING_UV_EXIT} through, but exited ${run_status}")
      judge_run "${name}" "${machine}" "${dir}" "${FAILING_UV_EXIT}"
    done
  done
done

###########
# SUMMARY #
###########

if [[ ${failed_runs} -gt 0 || ${discovery_failures} -gt 0 ]]; then
  printf "\n%d of %d runs failed across %d project commands on %s" \
    "${failed_runs}" "${runs}" "${#commands[@]}" "${MACHINES[*]}"
  [[ ${discovery_failures} -gt 0 ]] &&
    printf "; %d files broke the discovery rule" "${discovery_failures}"
  printf "\n"
  exit 1
fi

printf "✅ %d runs passed across %d project commands (%s) on %s\n" \
  "${runs}" "${#commands[@]}" "${commands[*]}" "${MACHINES[*]}"
