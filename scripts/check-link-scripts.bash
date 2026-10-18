#!/usr/bin/env bash
# Check that every tools/*/link.bash writes nothing in check mode, and links only into directories
# the broken-symlink sweep covers.
#
# Run with: bash scripts/check-link-scripts.bash
#
# dcheck runs each link.bash with DOTFILES_CHECK=true to report link status, and promises to change
# nothing. A link.bash that hand-rolls `ln` instead of calling symlink() can break that promise
# without anyone noticing.
#
# `symlinks` removes broken links only in the directories any_broken_symlink_dirs and
# repo_symlink_dirs list in tools/bash/utils.bash. A link in any other directory stays behind,
# broken, once its source is deleted, so each link a script creates must land in one of them.
#
# For each link.bash, this builds its links for real in an empty temporary HOME, then removes them
# one at a time and runs the script in check mode, failing if check mode puts anything back.
# Removing one link at a time matters: most link.bash files use `set -e`, so a check that reports an
# earlier link as missing stops the script before it reaches the later ones. Exit codes are
# ignored, because check mode returns non-zero whenever a link is missing.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES

# Run a link.bash the way CI does, wherever this check runs: macOS's own bash (3.2, not a newer
# Homebrew bash) and no terminal. Without this, a script that only works in a newer bash or with
# TERM set passes locally and fails in CI.
run_link_script() {
  env -u TERM /bin/bash "$@"
}

# tools/bash/utils.bash sources its siblings through ${HOME}/Repos/ooloth/dotfiles, so a temporary
# HOME needs the repo at that path. It is a fixture, not a link any link.bash made, so the snapshot
# and the list of links to remove both leave it out.
make_fake_home() {
  local dir
  dir="$(mktemp -d)"
  mkdir -p "${dir}/Repos/ooloth"
  ln -s "${DOTFILES}" "${dir}/Repos/ooloth/dotfiles"
  echo "${dir}"
}

# Whether the sweep in `symlinks` reaches a link in this directory, asked of utils.bash so the two
# can't disagree about which directories it covers or how deep.
is_swept_dir() {
  local fake_home="$1" dir="$2"
  HOME="${fake_home}" run_link_script -c \
    "source '${fake_home}/Repos/ooloth/dotfiles/tools/bash/utils.bash'; is_swept_link_dir '${dir}'"
}

# Every path under a fake HOME except the repo fixture, with each symlink's target, in a stable
# order.
snapshot() {
  local dir="$1"
  find "${dir}" -mindepth 1 -path "${dir}/Repos" -prune -o -print | sort |
    while IFS= read -r path; do
      if [[ -L "${path}" ]]; then
        printf "%s -> %s\n" "${path}" "$(readlink "${path}")"
      else
        printf "%s\n" "${path}"
      fi
    done
}

failed=()
checked=0

# The scripts `symlinks` runs, asked of utils.bash so this checks exactly that list. utils.bash needs
# a HOME holding the repo, and DOTFILES is set back afterwards so the paths are this checkout's.
list_home="$(make_fake_home)"
if ! link_scripts_list="$(HOME="${list_home}" run_link_script -c \
  "source '${list_home}/Repos/ooloth/dotfiles/tools/bash/utils.bash'; DOTFILES='${DOTFILES}'; link_scripts")"; then
  echo "❌ link_scripts in tools/bash/utils.bash found no link.bash scripts"
  exit 1
fi
rm -rf "${list_home}"

while IFS= read -r link_script; do
  name="${link_script#"${DOTFILES}/"}"

  checked=$((checked + 1))
  fake_home="$(make_fake_home)"
  if ! output="$(HOME="${fake_home}" run_link_script "${link_script}" 2>&1)"; then
    printf "❌ %s failed to create its links in an empty HOME:\n" "${name}"
    printf "%s\n" "${output//${fake_home}/\$HOME}" | sed 's/^/    /'
    failed+=("${name}")
    rm -rf "${fake_home}"
    continue
  fi

  links=()
  while IFS= read -r link; do
    links+=("${link}")
  done < <(find "${fake_home}" -path "${fake_home}/Repos" -prune -o -type l -print | sort)

  unswept=()
  for link in ${links[@]+"${links[@]}"}; do
    is_swept_dir "${fake_home}" "$(dirname "${link}")" || unswept+=("${link}")
  done
  if [[ ${#unswept[@]} -gt 0 ]]; then
    printf "❌ %s links into a directory the broken-symlink sweep does not cover:\n" "${name}"
    printf "    %s\n" "${unswept[@]/#${fake_home}/\$HOME}"
    printf "    Add the directory to repo_symlink_dirs in tools/bash/utils.bash\n"
    failed+=("${name}")
    rm -rf "${fake_home}"
    continue
  fi

  # A link.bash may create no links on this machine; ${arr[@]+...} keeps bash 3.2's set -u from
  # treating the empty array as unbound
  for link in ${links[@]+"${links[@]}"}; do
    target="$(readlink "${link}")"
    rm "${link}"
    before="$(snapshot "${fake_home}")"

    HOME="${fake_home}" DOTFILES_CHECK=true run_link_script "${link_script}" >/dev/null 2>&1

    after="$(snapshot "${fake_home}")"
    if [[ "${before}" != "${after}" ]]; then
      printf "❌ %s wrote in check mode after %s was removed:\n%s\n" "${name}" \
        "${link/#${fake_home}/\$HOME}" \
        "$(diff <(echo "${before}") <(echo "${after}") | sed "s|${fake_home}|\$HOME|g")"
      failed+=("${name}")
      break
    fi

    ln -s "${target}" "${link}"
  done

  rm -rf "${fake_home}"
done <<<"${link_scripts_list}"

if [[ ${#failed[@]} -gt 0 ]]; then
  printf "\n%d of %d link.bash scripts failed\n" "${#failed[@]}" "${checked}"
  exit 1
fi

printf "✅ %d link.bash scripts wrote nothing in check mode and link only into swept directories\n" \
  "${checked}"
