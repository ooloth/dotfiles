#!/usr/bin/env zsh

set -euo pipefail

source "${DOTFILES}/tools/zsh/utils.zsh"

main() {
  # TODO: install node via fnm if npm command is missing?

  info "✨ Updating Node $(node -v) global dependencies"

  # see: https://docs.npmjs.com/cli/v9/commands/npm-update?v=true#updating-globally-installed-packages
  packages=(
    @anthropic-ai/claude-code
    npm
    npm-check
    trash-cli
  )

  installed_packages=$(npm list -g --depth=0 || true)
  outdated_packages=$(npm outdated -g || true)

  is_package_installed() {
    local package="$1"
    echo "$installed_packages" | grep -q " ${package}@"
    return $? # Return the exit status of the grep command
  }

  is_package_outdated() {
    local package="$1"
    echo "$outdated_packages" | grep -q "^${package}"
    return $? # Return the exit status of the grep command
  }

  packages_to_add=()
  packages_to_update=()

  for package in "${packages[@]}"; do
    if ! is_package_installed "$package"; then
      packages_to_add+=("$package")
    elif is_package_outdated "$package"; then
      packages_to_update+=("$package")
    fi
  done

  echo
  for package in "${packages_to_add[@]}"; do
    printf "📦 Installing %s\n" "$package"
  done

  for package in "${packages_to_update[@]}"; do
    printf "🚀 Updating %s\n" "$package"
  done

  if [ ${#packages_to_add[@]} -gt 0 ] || [ ${#packages_to_update[@]} -gt 0 ]; then
    # prefer "-g" over "--location=global" to support older versions of npm
    npm install -g --loglevel=error "${packages_to_add[@]}" "${packages_to_update[@]}"
  fi

  printf "🎉 All npm packages are installed and up to date\n"
}

main "$@"
