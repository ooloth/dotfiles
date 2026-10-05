#!/usr/bin/env bash
# Check that every tools/*/link.bash writes nothing in check mode.
#
# Run with: bash scripts/check-link-scripts.bash
#
# dcheck runs each link.bash with DOTFILES_CHECK=true to report link status, and promises to change
# nothing. A link.bash that hand-rolls `ln` instead of calling symlink() can break that promise
# without anyone noticing.
#
# For each link.bash, this builds its links for real in an empty temporary HOME, then removes them
# one at a time and runs the script in check mode, failing if check mode puts anything back.
# Removing one link at a time matters: most link.bash files use `set -e`, so a check that reports an
# earlier link as missing stops the script before it reaches the later ones. Exit codes are
# ignored, because check mode returns non-zero whenever a link is missing.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES

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

for link_script in "${DOTFILES}"/tools/*/link.bash; do
  # tools/@new and tools/@archive are a template and retired tools, not real tools
  [[ "${link_script}" == "${DOTFILES}/tools/@"* ]] && continue
  name="${link_script#"${DOTFILES}/"}"

  checked=$((checked + 1))
  fake_home="$(make_fake_home)"
  if ! output="$(HOME="${fake_home}" bash "${link_script}" 2>&1)"; then
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

  # A link.bash may create no links on this machine; ${arr[@]+...} keeps bash 3.2's set -u from
  # treating the empty array as unbound
  for link in ${links[@]+"${links[@]}"}; do
    target="$(readlink "${link}")"
    rm "${link}"
    before="$(snapshot "${fake_home}")"

    HOME="${fake_home}" DOTFILES_CHECK=true bash "${link_script}" >/dev/null 2>&1

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
done

if [[ ${#failed[@]} -gt 0 ]]; then
  printf "\n%d of %d link.bash scripts failed\n" "${#failed[@]}" "${checked}"
  exit 1
fi

printf "✅ %d link.bash scripts wrote nothing in check mode\n" "${checked}"
