#!/usr/bin/env bash
# Check how every project command behaves in a directory it knows and in one it does not.
#
# Run with: bash scripts/check-project-commands.bash
#
# A project command (check, test, start, ...) is a features/*/*.bash script that picks what to run
# from the name of the current directory and the machine. Its only callers are the shell aliases in
# features/*/shell.zsh, so a command that finds no case for the directory must say so on stderr and
# exit non-zero, or the caller sees success when nothing ran.
#
# Every run uses a temporary HOME whose Repos/ooloth/dotfiles links to the checkout under test,
# because tools/bash/utils.bash resets DOTFILES to that path. It runs each command with macOS's own
# bash (3.2) and TERM unset, the way CI does, once as the work machine and once as a personal one.
# `air` stands for every personal machine, since `mini` takes the same branch. `uv` is replaced by a
# stub on PATH that exits with UV_STUB_STATUS, so no real tool runs.
#
# T0  sourcing tools/bash/utils.bash keeps the COMPUTER this check sets, so is_work follows it.
# T1  in a directory no case matches, every command exits non-zero.
# T2  in the same runs, stderr names the command and the directory, and stdout does not.
# T3  check and test in the shared projects exit 0 with no no-match message when uv exits 0.
# T4  check and test in the shared projects exit with uv's status when uv fails.
set -uo pipefail

CHECKOUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MACHINES=(work air)
UNMATCHED_DIR_NAME="no-project-matches-this"
# Every project command reads the current directory with this line, which is how this finds them
DISPATCH_MARKER="current_dir=\$(basename"
UV_FAILURE_STATUS=3

# The labels of the outer case in check.bash and test.bash: projects shared across machines, which
# run uv whatever COMPUTER is. Hard-coded because parsing case labels out of bash would be fragile.
SHARED_PROJECTS=(agency-1 agency-2 agent-1 agent-2)
SHARED_PROJECT_COMMANDS=(check test)

ROOT="$(mktemp -d)"
trap 'rm -rf "${ROOT}"' EXIT

FAKE_HOME="${ROOT}/home"
FAKE_DOTFILES="${FAKE_HOME}/Repos/ooloth/dotfiles"
STUB_BIN="${ROOT}/bin"
PROJECTS="${ROOT}/projects"
OUTPUT="${ROOT}/output"

mkdir -p "${FAKE_HOME}/Repos/ooloth" "${STUB_BIN}" "${PROJECTS}" "${OUTPUT}"
ln -s "${CHECKOUT}" "${FAKE_DOTFILES}"

cat >"${STUB_BIN}/uv" <<'STUB'
#!/bin/sh
exit "${UV_STUB_STATUS:-0}"
STUB
chmod +x "${STUB_BIN}/uv"

failures=0

fail() {
  failures=$((failures + 1))
  printf "❌ %s\n" "$1"
}

# Print a captured stream indented, with the temporary paths replaced by readable names
show() {
  local label="$1" file="$2"
  printf "    %s:\n" "${label}"
  if [[ -s "${file}" ]]; then
    sed -e "s|${FAKE_DOTFILES}|\$DOTFILES|g" -e "s|${ROOT}|\$TMP|g" -e 's/^/      /' "${file}"
  else
    printf "      (empty)\n"
  fi
}

# Run a command script the way its alias does, from a project directory, as one machine.
# Sets RUN_STATUS and leaves the streams in ${OUTPUT}/stdout and ${OUTPUT}/stderr.
run_command() {
  local script="$1" dir_name="$2" machine="$3" uv_status="$4"
  local dir="${PROJECTS}/${dir_name}"
  mkdir -p "${dir}"
  (
    cd "${dir}" &&
      HOME="${FAKE_HOME}" DOTFILES="${FAKE_DOTFILES}" COMPUTER="${machine}" \
        PATH="${STUB_BIN}:${PATH}" UV_STUB_STATUS="${uv_status}" \
        env -u TERM /bin/bash "${script}"
  ) </dev/null >"${OUTPUT}/stdout" 2>"${OUTPUT}/stderr"
  RUN_STATUS=$?
}

report_run() {
  local summary="$1" command="$2" dir_name="$3" machine="$4"
  fail "${summary}"
  printf "    command: %s, dir: /%s, COMPUTER=%s, exit code: %s\n" \
    "${command}" "${dir_name}" "${machine}" "${RUN_STATUS}"
  show stdout "${OUTPUT}/stdout"
  show stderr "${OUTPUT}/stderr"
}

no_match_message() {
  printf "No '%s' case defined for '/%s'" "$1" "$2"
}

#######
# T0  #
#######

# The probe sources utils.bash under the same options the commands use, then asks is_work
probe="${ROOT}/is-work-probe.bash"
cat >"${probe}" <<'PROBE'
set -euo pipefail
source "${DOTFILES}/tools/bash/utils.bash"
if is_work; then echo "is_work=true COMPUTER=${COMPUTER}"; else echo "is_work=false COMPUTER=${COMPUTER}"; fi
PROBE

for machine in "${MACHINES[@]}"; do
  expected="false"
  [[ "${machine}" == "work" ]] && expected="true"
  result="$(HOME="${FAKE_HOME}" DOTFILES="${FAKE_DOTFILES}" COMPUTER="${machine}" \
    env -u TERM /bin/bash "${probe}" 2>&1)"
  if [[ "${result}" != "is_work=${expected} COMPUTER=${machine}" ]]; then
    fail "T0: with COMPUTER=${machine} set, sourcing tools/bash/utils.bash should leave is_work ${expected}"
    printf "    got: %s\n" "${result}"
  fi
done

##############
# T1 and T2  #
##############

commands=()
while IFS= read -r script; do
  commands+=("${script}")
done < <(grep -lF "${DISPATCH_MARKER}" "${CHECKOUT}"/features/*/*.bash | sort)

if [[ ${#commands[@]} -eq 0 ]]; then
  fail "T1: found no features/*/*.bash containing '${DISPATCH_MARKER}', so nothing was checked"
else
  printf "Project commands found:"
  for script in "${commands[@]}"; do
    printf " %s" "$(basename "${script}" .bash)"
  done
  printf "\n"
fi

for script in ${commands[@]+"${commands[@]}"}; do
  command="$(basename "${script}" .bash)"
  message="$(no_match_message "${command}" "${UNMATCHED_DIR_NAME}")"

  for machine in "${MACHINES[@]}"; do
    run_command "${script}" "${UNMATCHED_DIR_NAME}" "${machine}" 0

    if [[ ${RUN_STATUS} -eq 0 ]]; then
      report_run "T1: '${command}' exited 0 in a directory no case matches" \
        "${command}" "${UNMATCHED_DIR_NAME}" "${machine}"
    fi

    if ! grep -qF "${message}" "${OUTPUT}/stderr"; then
      report_run "T2: '${command}' did not print \"${message}\" on stderr" \
        "${command}" "${UNMATCHED_DIR_NAME}" "${machine}"
    fi

    if grep -qF "${message}" "${OUTPUT}/stdout"; then
      report_run "T2: '${command}' printed \"${message}\" on stdout" \
        "${command}" "${UNMATCHED_DIR_NAME}" "${machine}"
    fi
  done
done

##############
# T3 and T4  #
##############

for command in "${SHARED_PROJECT_COMMANDS[@]}"; do
  script="${CHECKOUT}/features/${command}/${command}.bash"

  for dir_name in "${SHARED_PROJECTS[@]}"; do
    message="$(no_match_message "${command}" "${dir_name}")"

    for machine in "${MACHINES[@]}"; do
      run_command "${script}" "${dir_name}" "${machine}" 0
      if [[ ${RUN_STATUS} -ne 0 ]]; then
        report_run "T3: '${command}' should exit 0 when uv exits 0" \
          "${command}" "${dir_name}" "${machine}"
      fi
      if grep -qF "No '${command}' case defined" "${OUTPUT}/stderr"; then
        report_run "T3: '${command}' printed \"${message}\" after uv ran" \
          "${command}" "${dir_name}" "${machine}"
      fi

      run_command "${script}" "${dir_name}" "${machine}" "${UV_FAILURE_STATUS}"
      if [[ ${RUN_STATUS} -ne ${UV_FAILURE_STATUS} ]]; then
        report_run "T4: '${command}' should exit ${UV_FAILURE_STATUS}, uv's status" \
          "${command}" "${dir_name}" "${machine}"
      fi
    done
  done
done

if [[ ${failures} -gt 0 ]]; then
  printf "\n%d project command checks failed\n" "${failures}"
  exit 1
fi

printf "✅ %d project commands exit non-zero with a message when no case matches, and check and test exit with uv's status in shared projects\n" \
  "${#commands[@]}"
