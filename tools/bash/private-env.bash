# shellcheck shell=bash
# Loads this machine's private values: the PRIVATE_KEY=value lines in the ignored private.env at the
# repo root, which hold what must not appear in this public repo. private.env.example lists every key.
#
# .zshrc calls load_private_env --warn at startup, and tools/bash/utils.bash calls it quietly for a
# script started outside a configured zsh, such as a Rex tab. Both bash 3.2 and zsh source this file.

# Exports each PRIVATE_KEY=value line of FILE, removing one pair of quotes around the value. FILE is
# read as text and never sourced, so a value cannot run a command and a line cannot set a variable
# outside PRIVATE_*.
#
# With --warn, also names on stderr each line that is not such an assignment, a missing FILE, and
# each key EXAMPLE marks with `# machines:` for this machine ($COMPUTER) that FILE leaves unset or
# empty. Orbs and CI have no private values, so there it warns about nothing.
#
# Usage: load_private_env [--warn] [FILE] [EXAMPLE]
load_private_env() {
  local warn=false
  if [[ "${1:-}" == "--warn" ]]; then
    warn=true
    shift
  fi
  local file="${1:-${DOTFILES}/private.env}"
  local example="${2:-${DOTFILES}/private.env.example}"
  if [[ -n "${CI:-}" || -n "${AMP_ORB:-}" ]]; then
    warn=false
  fi

  if [[ ! -f "${file}" ]]; then
    if ${warn}; then
      printf '⚠️  No %s, so no private values are set. Copy private.env.example there and fill in the keys this machine needs.\n' "${file}" >&2
    fi
    return 0
  fi

  local line key value line_no=0 loaded=" "
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line_no=$((line_no + 1))
    if [[ -z "${line//[[:space:]]/}" || "${line}" == "#"* ]]; then
      continue
    fi
    key="${line%%=*}"
    value="${line#*=}"
    if [[ "${line}" != *=* || ! "${key}" =~ ^PRIVATE_[A-Z0-9_]+$ ]]; then
      if ${warn}; then
        printf '⚠️  %s line %d is not a PRIVATE_KEY=value line, so it was skipped.\n' "${file}" "${line_no}" >&2
      fi
      continue
    fi
    if [[ ${#value} -ge 2 && ("${value}" == \"*\" || "${value}" == \'*\') ]]; then
      value="${value:1:${#value}-2}"
    fi
    export "${key}=${value}"
    if [[ -n "${value}" ]]; then
      loaded+="${key} "
    fi
  done <"${file}"

  if ! ${warn} || [[ ! -f "${example}" ]]; then
    return 0
  fi
  local machines="" missing=""
  while IFS= read -r line || [[ -n "${line}" ]]; do
    case "${line}" in
    "# machines:"*)
      machines=" ${line#"# machines:"} "
      ;;
    PRIVATE_*=*)
      key="${line%%=*}"
      if [[ "${machines}" == *" ${COMPUTER:-} "* && "${loaded}" != *" ${key} "* ]]; then
        missing+=" ${key}"
      fi
      machines=""
      ;;
    esac
  done <"${example}"
  if [[ -n "${missing}" ]]; then
    printf '⚠️  %s sets no value for%s, which private.env.example says this machine needs.\n' "${file}" "${missing}" >&2
  fi
}
