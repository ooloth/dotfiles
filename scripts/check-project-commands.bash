#!/usr/bin/env bash
# Check how every project command dispatches on the directory it runs in.
#
# Run with: bash scripts/check-project-commands.bash
#
# A project command (check, new, run, test, ...) picks what to do from the basename of the current
# directory and, for most projects, from which machine it runs on. This checks, on a work machine
# and a non-work one:
#
#   T0  COMPUTER chooses the machine branch, so the runs below really cover both branches
#   T1  every command exits non-zero in a directory it has no case for
#   T2  that no-match prints "No '<command>' case defined for '/<dir>'" to stderr, not stdout
#   T3  check and test in a shared project exit 0 with no no-match message when the tool succeeds
#   T4  check and test in a shared project exit with the tool's own status when it fails
#
# `uv` is stubbed on PATH, because it is the external tool the shared projects hand off to.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Every run happens once per machine branch. `air` stands for the non-work branch, which `mini`
# shares.
MACHINES=(work air)

# The labels of the outer `case` in check.bash and test.bash: projects shared across machines.
# They are listed here rather than parsed out of the scripts, because parsing bash `case` labels
# would be fragile.
SHARED_PROJECTS=(agency-1 agency-2 agent-1 agent-2)
SHARED_PROJECT_COMMANDS=(check test)

# A directory name no command has a case for
UNMATCHED_PROJECT="no-such-project"

# Everything this check creates lives under one temporary directory, removed on exit.
scratch="$(mktemp -d)"
trap 'rm -rf "${scratch}"' EXIT

# tools/bash/utils.bash sets DOTFILES to ${HOME}/Repos/ooloth/dotfiles, so a temporary HOME needs
# the checkout under test at that path. Without it, a run from a worktree would test the main
# checkout.
fake_home="${scratch}/home"
mkdir -p "${fake_home}/Repos/ooloth"
ln -s "${DOTFILES}" "${fake_home}/Repos/ooloth/dotfiles"
fake_dotfiles="${fake_home}/Repos/ooloth/dotfiles"

# One stub `uv` per exit status the checks need. Each ignores its arguments.
make_uv_stub() {
  local status="$1"
  local dir="${scratch}/uv-exits-${status}"
  mkdir -p "${dir}"
  printf '#!/bin/sh\nexit %s\n' "${status}" >"${dir}/uv"
  chmod +x "${dir}/uv"
  echo "${dir}"
}
uv_succeeds="$(make_uv_stub 0)"
uv_fails="$(make_uv_stub 3)"
UV_FAILURE_STATUS=3

project_dir() {
  local dir="${scratch}/projects/$1"
  mkdir -p "${dir}"
  echo "${dir}"
}

# Run bash the way CI does, wherever this check runs: macOS's own bash (3.2, not a newer Homebrew
# bash) and no terminal, under the temporary HOME and the given machine. The caller's own
# environment otherwise passes through.
#   run_as <machine> <uv stub dir> <working dir> <bash args...>
# Sets: run_status, run_stdout, run_stderr
run_as() {
  local machine="$1" uv_dir="$2" work_dir="$3"
  shift 3
  local out="${scratch}/stdout" err="${scratch}/stderr"
  (
    cd "${work_dir}" &&
      HOME="${fake_home}" DOTFILES="${fake_dotfiles}" COMPUTER="${machine}" \
        PATH="${uv_dir}:${PATH}" env -u TERM /bin/bash "$@"
  ) >"${out}" 2>"${err}" </dev/null
  run_status=$?
  run_stdout="$(cat "${out}")"
  run_stderr="$(cat "${err}")"
}

failures=0
checks=0

pass() {
  checks=$((checks + 1))
}

# fail <test> <what was run> <expected> <observed>
fail() {
  checks=$((checks + 1))
  failures=$((failures + 1))
  printf "❌ %s: %s\n    expected: %s\n    observed: %s\n" "$1" "$2" "$3" "$4"
}

# Prints captured output indented under a failure, so the reader sees what the command said
show_output() {
  local label="$1" text="$2"
  [[ -z "${text}" ]] && return
  printf "    %s:\n" "${label}"
  printf "%s\n" "${text}" | sed 's/^/      /'
}

no_match_message() {
  printf "No '%s' case defined for '/%s'" "$1" "$2"
}

######################################
# T0: COMPUTER chooses the machine   #
######################################

home_dir="$(project_dir home)"
for machine in "${MACHINES[@]}"; do
  # The inner bash expands DOTFILES, not this one
  run_as "${machine}" "${uv_succeeds}" "${home_dir}" \
    -c "source \"\${DOTFILES}/tools/bash/utils.bash\" && is_work"
  if [[ "${machine}" == "work" ]]; then expected=0; else expected=1; fi
  if [[ "${expected}" -eq 0 && "${run_status}" -eq 0 ]] ||
    [[ "${expected}" -ne 0 && "${run_status}" -ne 0 ]]; then
    pass
  else
    if [[ "${expected}" -eq 0 ]]; then want="is_work true"; else want="is_work false"; fi
    fail "T0 COMPUTER chooses the machine branch" "COMPUTER=${machine}, then is_work" \
      "${want}" "is_work exited ${run_status}"
    show_output "stderr" "${run_stderr}"
  fi
done

##############################
# Find every project command #
##############################

# A project command is any features/*/*.bash that dispatches on the current directory's name
commands=()
for script in "${DOTFILES}"/features/*/*.bash; do
  # The literal text to find, not an expansion
  if grep -qF "current_dir=\$(basename" "${script}"; then
    commands+=("${script#"${DOTFILES}/"}")
  fi
done

if [[ ${#commands[@]} -eq 0 ]]; then
  printf "❌ Found no project commands (features/*/*.bash containing 'current_dir=\$(basename')\n"
  exit 1
fi

printf "Project commands found (%d):\n" "${#commands[@]}"
printf "    %s\n" "${commands[@]}"
printf "\n"

#####################################################
# T1, T2: a directory with no case fails and says so #
#####################################################

unmatched_dir="$(project_dir "${UNMATCHED_PROJECT}")"
for command_path in "${commands[@]}"; do
  command_name="$(basename "${command_path}" .bash)"
  message="$(no_match_message "${command_name}" "${UNMATCHED_PROJECT}")"

  for machine in "${MACHINES[@]}"; do
    run_as "${machine}" "${uv_succeeds}" "${unmatched_dir}" "${fake_dotfiles}/${command_path}"
    where="'${command_name}' on ${machine} in /${UNMATCHED_PROJECT}"

    if [[ "${run_status}" -ne 0 ]]; then
      pass
    else
      fail "T1 unmatched directory exits non-zero" "${where}" "non-zero exit" "exit 0"
      show_output "stderr" "${run_stderr}"
    fi

    if [[ "${run_stderr}" == *"${message}"* ]]; then
      pass
    else
      fail "T2 no-match message on stderr" "${where}" "stderr contains \"${message}\"" \
        "stderr does not (exit ${run_status})"
      show_output "stderr" "${run_stderr}"
    fi

    if [[ "${run_stdout}" != *"${message}"* ]]; then
      pass
    else
      fail "T2 no-match message not on stdout" "${where}" "stdout without \"${message}\"" \
        "stdout contains it"
      show_output "stdout" "${run_stdout}"
    fi
  done
done

###########################################################
# T3, T4: a shared project exits with its tool's status   #
###########################################################

for command_name in "${SHARED_PROJECT_COMMANDS[@]}"; do
  command_path="features/${command_name}/${command_name}.bash"

  for project in "${SHARED_PROJECTS[@]}"; do
    dir="$(project_dir "${project}")"
    message="$(no_match_message "${command_name}" "${project}")"

    for machine in "${MACHINES[@]}"; do
      where="'${command_name}' on ${machine} in /${project}"

      # T3: the tool succeeds
      run_as "${machine}" "${uv_succeeds}" "${dir}" "${fake_dotfiles}/${command_path}"
      if [[ "${run_status}" -eq 0 && "${run_stderr}" != *"${message}"* ]]; then
        pass
      else
        observed="exit ${run_status}"
        [[ "${run_stderr}" == *"${message}"* ]] && observed+=", stderr contains \"${message}\""
        fail "T3 shared project succeeds with its tool" "${where}, uv exits 0" \
          "exit 0, no no-match message" "${observed}"
        show_output "stderr" "${run_stderr}"
      fi

      # T4: the tool fails
      run_as "${machine}" "${uv_fails}" "${dir}" "${fake_dotfiles}/${command_path}"
      if [[ "${run_status}" -eq "${UV_FAILURE_STATUS}" ]]; then
        pass
      else
        fail "T4 shared project fails with its tool's status" \
          "${where}, uv exits ${UV_FAILURE_STATUS}" "exit ${UV_FAILURE_STATUS}" \
          "exit ${run_status}"
        show_output "stderr" "${run_stderr}"
      fi
    done
  done
done

###########
# Summary #
###########

if [[ "${failures}" -gt 0 ]]; then
  printf "\n%d of %d project command checks failed\n" "${failures}" "${checks}"
  exit 1
fi

printf "✅ %d project command checks passed\n" "${checks}"
