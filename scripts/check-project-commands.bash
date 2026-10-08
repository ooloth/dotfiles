#!/usr/bin/env bash
# Check that every project command (check, test, start, ...) fails when no case matches the current
# directory, and exits with its tool's status when one does.
#
# Run with: bash scripts/check-project-commands.bash
#
# Each features/*/*.bash that dispatches on `current_dir=$(basename ...)` picks what to run from the
# name of the current directory and the machine. These are what the shell aliases `check`, `test`,
# `start` and the rest run. A command that finds no case must exit non-zero, so a caller (an agent,
# a loop, `&&`) cannot mistake "nothing ran" for "it passed". A command that finds one must exit
# with its tool's status.
#
# Every run uses a temporary HOME that links to this checkout, because tools/bash/utils.bash sets
# DOTFILES from HOME, so a run from a worktree would otherwise test the main checkout. Every tool a
# matched case calls is replaced by a stub: on PATH for a bare name, inside the project directory
# for a path like ./bin/test. PATH holds only the system directories besides the stubs.
#
#   T0  after sourcing tools/bash/utils.bash, is_work follows COMPUTER (work: true, air: false)
#   T1  every project command, run in a directory no case matches, exits non-zero and runs no tool
#   T2  in those runs, stderr names the command and directory, and stdout does not
#   T3  every matched case runs exactly its tools, and exits 0 with no no-match message when they
#       all succeed
#   T4  every matched case exits with a tool's status when that tool fails, and runs nothing after it
#   T5  no_case_defined ends the script non-zero even where `set -e` is suspended (if, ||)
#   T6  no_case_defined with no command name ends the script non-zero
#   T7  MATCHED_CASES below lists every case label in every project command, so a case added later
#       cannot go untested
#   T8  a COMPUTER no is_* function recognises (Work, bogus) is replaced by a detected machine
#   T9  a case for one machine only, run with the other machine's COMPUTER, reaches the no-match
#       branch and runs none of its tools
#
# Adding, removing or changing a case in a project command (its labels, machine or the tools it
# runs) means updating MATCHED_CASES below. T7 fails until the labels match, and T3/T4 fail until
# the tools match.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# `air` stands for every non-work machine, which `mini` shares
MACHINES=(work air)

# A directory name no command has a case for
UNMATCHED_DIR="no-project-command-case"

# Every matched case, one line per case label line: command | machine | labels | calls
#   machine  work or air for a case inside an is_work branch; any for a case that runs on both
#   labels   the directory names on that label line
#   calls    the tools the case runs, in order. A name containing / is a path relative to the
#            project directory; any other name is stubbed on PATH.
# T7 fails when a command's case labels differ from this table, so a new case must be added here.
MATCHED_CASES="
check|any|agency-1 agency-2|uv
check|any|agent-1 agent-2|uv
check|work|ops-1 ops-2 ops-3|uv
check|work|mapapp-1 mapapp-2 mapapp-3|./bin/check.sh
check|work|react-app|npm
check|work|spade-flows|./bin/dev/check.sh
check|air|media-tools|uv
check|air|michaeluloth.com|npm npm npm
new|any|advent-of-code|./bin/new
restart|work|spade-flows|./bin/dev/restart.sh
run|work|spade-flows|./bin/dev/run.sh
run|air|advent-of-code|./bin/run
start|work|cauldron|du
start|work|ops-1 ops-2|docker uvicorn
start|work|genie|du
start|work|mapapp-1|./bin/dev.sh
start|work|mapapp-2|./bin/dev.sh
start|work|mapapp-3|./bin/dev.sh
start|work|mapapp-4|./bin/dev.sh
start|work|platelet|du
start|work|platelet-ui|cauldron du genie du pl du skurge du plu n du
start|work|processing-witch|python
start|work|react-app|npm npm
start|work|skurge|du
start|work|spade-flows|./bin/dev/start.sh
start|work|tech|ns
start|air|michaeluloth.com|npm
stop|work|cauldron|dd
stop|work|ops-1 ops-2|docker
stop|work|genie|dd
stop|work|mapapp-1|dd
stop|work|mapapp-2|dd
stop|work|mapapp-3|dd
stop|work|platelet-ui|cauldron dd genie dd pl dd skurge dd plu dd
stop|work|skurge|dd
stop|work|spade-flows|./bin/dev/stop.sh
submit|any|advent-of-code|bin/submit
test|any|agency-1 agency-2|uv
test|any|agent-1 agent-2|uv
test|work|ops-1 ops-2 ops-3|uv
test|work|mapapp-1 mapapp-2 mapapp-3|./bin/test.sh
test|work|react-app|npm
test|work|spade-flows|./bin/dev/test.sh
test|air|advent-of-code|./bin/test
test|air|hub|pytest
test|air|media-tools|uv
test|air|michaeluloth.com|npm
test|air|scripts|pytest
"

# The exit status a failing stub returns, chosen to be distinguishable from 0 and 1
TOOL_FAILURE_STATUS=3

scratch="$(mktemp -d)" || { printf "FAIL could not create a temporary directory\n" >&2; exit 1; }
trap 'rm -rf "${scratch}"' EXIT

fake_home="${scratch}/home"
mkdir -p "${fake_home}/Repos/ooloth"
ln -s "${REPO}" "${fake_home}/Repos/ooloth/dotfiles"
dotfiles_under_test="${fake_home}/Repos/ooloth/dotfiles"

stub_bin="${scratch}/bin"
mkdir -p "${stub_bin}"

projects_dir="${scratch}/projects"
out="${scratch}/stdout"
err="${scratch}/stderr"
calls_log="${scratch}/calls.log"

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

# Writes a stub tool at <path> that appends <name> to the call log, then exits with
# TOOL_FAILURE_STATUS if it is call number STUB_FAIL_CALL of this run, and 0 otherwise.
make_stub() {
  local path="$1" name="$2"
  mkdir -p "$(dirname "${path}")"
  cat >"${path}" <<EOF
#!/bin/sh
call=\$((\$(wc -l <"\${STUB_LOG:?}") + 1))
printf '%s\n' '${name}' >>"\${STUB_LOG}"
[ "\${call}" -eq "\${STUB_FAIL_CALL:?}" ] && exit ${TOOL_FAILURE_STATUS}
exit 0
EOF
  chmod +x "${path}"
}

# Run bash the way CI does, wherever this check runs: macOS's own bash (3.2, not a newer Homebrew
# bash) and no terminal, under the fake HOME, the chosen machine, and a PATH where the only tools
# outside the system directories are the stubs. BASH_ENV is unset so no startup file runs.
#   usage: run_as <machine> <working dir> <failing call number, 0 for none> <bash args...>
# Writes stdout, stderr and the stubs' call log to ${out}, ${err} and ${calls_log}; sets run_status.
run_as() {
  local machine="$1" dir="$2" fail_call="$3"
  shift 3
  : >"${calls_log}"
  (
    cd "${dir}" || exit 99
    env -u TERM -u BASH_ENV \
      HOME="${fake_home}" \
      DOTFILES="${dotfiles_under_test}" \
      COMPUTER="${machine}" \
      PATH="${stub_bin}:/usr/bin:/bin:/usr/sbin:/sbin" \
      STUB_LOG="${calls_log}" \
      STUB_FAIL_CALL="${fail_call}" \
      /bin/bash "$@" </dev/null >"${out}" 2>"${err}"
  )
  run_status=$?
}

no_match_message() {
  local command="$1" dir="$2"
  printf "No '%s' case defined for '/%s'" "${command}" "${dir}"
}

# The directory names on every case label line of a script, one per line, sorted. `*)` is left
# out. A line this misreads shows up as a difference from MATCHED_CASES, so T7 fails loudly.
case_labels() {
  grep -E '^[[:space:]]*"?[A-Za-z0-9._-]+"?([[:space:]]*\|[[:space:]]*"?[A-Za-z0-9._-]+"?)*\)' "$1" |
    sed -E 's/\).*//' | tr '|' '\n' | tr -d ' \t"' | sort
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

# Every bare tool name in MATCHED_CASES gets a stub on PATH
while IFS='|' read -r _ _ _ calls; do
  for name in ${calls}; do
    [[ "${name}" == */* ]] || make_stub "${stub_bin}/${name}" "${name}"
  done
done <<<"${MATCHED_CASES}"

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

    problems=()
    [[ ${run_status} -ne 0 ]] || problems+=("exit 0, want non-zero")
    [[ -s "${calls_log}" ]] && problems+=("ran [$(tr '\n' ' ' <"${calls_log}")], want no tool")
    if [[ ${#problems[@]} -eq 0 ]]; then
      pass "T1 ${where}: exit ${run_status}, no tool ran"
    else
      fail "T1 ${where}: $(IFS=";"; echo "${problems[*]}")"
      show stdout "${out}"
      show stderr "${err}"
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

# ─── T3 + T4: every matched case ────────────────────────────

# Checks and reports the run just made. want_status and want_calls are what it should have done.
check_matched_run() {
  local id="$1" where="$2" command="$3" want_status="$4" want_calls="$5"
  local problems=() got_calls
  [[ ${run_status} -eq ${want_status} ]] || problems+=("exit ${run_status}, want ${want_status}")
  got_calls="$(tr '\n' ' ' <"${calls_log}")"
  [[ "${got_calls}" == "${want_calls}" ]] || problems+=("ran [${got_calls}], want [${want_calls}]")
  if grep -qF "No '${command}' case defined" "${out}" "${err}"; then
    problems+=("printed a no-match message")
  fi
  if [[ ${#problems[@]} -eq 0 ]]; then
    pass "${id} ${where}: exit ${run_status}"
  else
    fail "${id} ${where}: $(IFS=";"; echo "${problems[*]}")"
    show stderr "${err}"
  fi
}

while IFS='|' read -r command machine labels calls; do
  [[ -n "${command}" ]] || continue
  script="features/${command}/${command}.bash"
  read -r -a call_list <<<"${calls}"
  if [[ "${machine}" == "any" ]]; then machines=("${MACHINES[@]}"); else machines=("${machine}"); fi

  for label in ${labels}; do
    for run_machine in "${machines[@]}"; do
      dir="${projects_dir}/${command}-${run_machine}/${label}"
      mkdir -p "${dir}"
      for name in "${call_list[@]}"; do
        [[ "${name}" == */* ]] && make_stub "${dir}/${name}" "${name}"
      done
      where="${script} machine=${run_machine} dir=/${label}"

      run_as "${run_machine}" "${dir}" 0 "${dotfiles_under_test}/${script}"
      check_matched_run T3 "${where} (all tools succeed)" "${command}" 0 "${call_list[*]} "

      for ((n = 1; n <= ${#call_list[@]}; n++)); do
        run_as "${run_machine}" "${dir}" "${n}" "${dotfiles_under_test}/${script}"
        check_matched_run T4 \
          "${where} (call ${n} '${call_list[n - 1]}' exits ${TOOL_FAILURE_STATUS})" \
          "${command}" "${TOOL_FAILURE_STATUS}" "${call_list[*]:0:n} "
      done
    done
  done
done <<<"${MATCHED_CASES}"

# ─── T5 + T6: no_case_defined ends the script ───────────────
# Every no-match site today runs where `set -e` applies, so T1 alone would pass if the helper only
# returned non-zero. These call it where `set -e` is suspended, and with no command name.

helper_contexts=(
  'if no_case_defined probe; then echo then-branch; fi; echo reached'
  'no_case_defined probe || true; echo reached'
  'no_case_defined probe && true; echo reached'
)
for context in "${helper_contexts[@]}"; do
  run_as air "${projects_dir}/${UNMATCHED_DIR}" 0 -c \
    "set -euo pipefail; source \"\${DOTFILES}/tools/bash/utils.bash\"; ${context}"
  where="no_case_defined in: ${context}"
  if [[ ${run_status} -ne 0 ]] && ! grep -qE 'reached|then-branch' "${out}" &&
    grep -qF "$(no_match_message probe "${UNMATCHED_DIR}")" "${err}"; then
    pass "T5 ${where}: exit ${run_status}, nothing after it ran"
  else
    fail "T5 ${where}: exit ${run_status}, want non-zero, no output after the call, and the no-match message"
    show stdout "${out}"
    show stderr "${err}"
  fi
done

helper_contexts=(
  'no_case_defined; echo reached'
  'if no_case_defined; then echo then-branch; fi; echo reached'
)
for context in "${helper_contexts[@]}"; do
  run_as air "${projects_dir}/${UNMATCHED_DIR}" 0 -c \
    "set -euo pipefail; source \"\${DOTFILES}/tools/bash/utils.bash\"; ${context}"
  where="no_case_defined with no name in: ${context}"
  if [[ ${run_status} -ne 0 ]] && ! grep -qE 'reached|then-branch' "${out}"; then
    pass "T6 ${where}: exit ${run_status}, nothing after it ran"
  else
    fail "T6 ${where}: exit ${run_status}, want non-zero and no output after the call"
    show stdout "${out}"
    show stderr "${err}"
  fi
done

# ─── T7: MATCHED_CASES covers every case label ──────────────

for script in "${commands[@]}"; do
  command="$(basename "${script}" .bash)"
  in_script="$(case_labels "${REPO}/${script}")"
  in_table="$(while IFS='|' read -r c _ labels _; do
    [[ "${c}" == "${command}" ]] && tr ' ' '\n' <<<"${labels}"
  done <<<"${MATCHED_CASES}" | sort)"
  if [[ "${in_script}" == "${in_table}" ]]; then
    pass "T7 ${script}: MATCHED_CASES lists its $(grep -c . <<<"${in_script}") case labels"
  else
    fail "T7 ${script}: case labels differ from MATCHED_CASES (< script, > table):"
    diff <(echo "${in_script}") <(echo "${in_table}") | grep '^[<>]' | sed 's/^/      /'
  fi
done

while IFS='|' read -r command _ _ _; do
  [[ -n "${command}" ]] || continue
  [[ -f "${REPO}/features/${command}/${command}.bash" ]] ||
    fail "T7 MATCHED_CASES names '${command}', which has no features/${command}/${command}.bash"
done <<<"${MATCHED_CASES}"

# ─── T8: an unrecognised COMPUTER is replaced by detection ──
# A COMPUTER no is_* function recognises would send every command down the non-work branch with
# no machine matching. utils.bash must detect the machine instead. networksetup is called by
# absolute path, so the detected machine is whatever this Mac is; any known machine passes.

for bad_value in Work bogus AIR; do
  # shellcheck disable=SC2016 # expanded by the child bash, not here
  run_as "${bad_value}" "${projects_dir}/${UNMATCHED_DIR}" 0 -c \
    'source "${DOTFILES}/tools/bash/utils.bash"
     matches=0
     for check in is_air is_mini is_work; do "${check}" && matches=$((matches + 1)); done
     printf "%s %s\n" "${COMPUTER}" "${matches}"'
  read -r got_computer got_matches <"${out}"
  where="COMPUTER=${bad_value}"
  case "${got_computer:-}" in
    air | mini | work) known_machine=yes ;;
    *) known_machine=no ;;
  esac
  if [[ ${run_status} -eq 0 && "${known_machine}" == "yes" && "${got_matches:-}" == "1" ]]; then
    pass "T8 ${where}: detected COMPUTER=${got_computer}, exactly one is_* true"
  else
    fail "T8 ${where}: exit ${run_status}, COMPUTER=${got_computer:-} with ${got_matches:-?} is_* true; want air, mini or work with exactly one"
    show stderr "${err}"
  fi
done

# ─── T9: a machine's case does not run on the other machine ─
# Each case inside an is_work branch, run with the other machine's COMPUTER, must reach the no-match
# branch and run none of its tools. A label that also has a case on the other machine is skipped.

# Succeeds when MATCHED_CASES gives <command> a case for <label> on <machine> (or on any machine)
has_case_on() {
  local want_command="$1" want_label="$2" want_machine="$3" c m labels
  while IFS='|' read -r c m labels _; do
    [[ "${c}" == "${want_command}" ]] || continue
    [[ "${m}" == "${want_machine}" || "${m}" == "any" ]] || continue
    grep -qxF "${want_label}" <(tr ' ' '\n' <<<"${labels}") && return 0
  done <<<"${MATCHED_CASES}"
  return 1
}

while IFS='|' read -r command machine labels calls; do
  [[ "${machine}" == "work" || "${machine}" == "air" ]] || continue
  if [[ "${machine}" == "work" ]]; then other=air; else other=work; fi
  script="features/${command}/${command}.bash"
  read -r -a call_list <<<"${calls}"

  for label in ${labels}; do
    has_case_on "${command}" "${label}" "${other}" && continue
    dir="${projects_dir}/${command}-${other}-crossed/${label}"
    mkdir -p "${dir}"
    for name in "${call_list[@]}"; do
      [[ "${name}" == */* ]] && make_stub "${dir}/${name}" "${name}"
    done
    where="${script} machine=${other} dir=/${label} (case is only on ${machine})"
    run_as "${other}" "${dir}" 0 "${dotfiles_under_test}/${script}"

    problems=()
    [[ ${run_status} -ne 0 ]] || problems+=("exit 0, want non-zero")
    grep -qF "$(no_match_message "${command}" "${label}")" "${err}" ||
      problems+=("no no-match message on stderr")
    [[ -s "${calls_log}" ]] && problems+=("ran [$(tr '\n' ' ' <"${calls_log}")], want no tool")
    if [[ ${#problems[@]} -eq 0 ]]; then
      pass "T9 ${where}: exit ${run_status}, no tool ran"
    else
      fail "T9 ${where}: $(IFS=";"; echo "${problems[*]}")"
      show stderr "${err}"
    fi
  done
done <<<"${MATCHED_CASES}"

printf "\n%d passed, %d failed\n" "${passed}" "${failed}"
[[ ${failed} -eq 0 ]] || exit 1
