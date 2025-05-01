#!/usr/bin/env zsh

# TODO: install node via fnm if missing?

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/config/zsh/aliases.zsh"
source "$DOTFILES/config/zsh/utils.zsh"

info "✨ Updating Node $(node -v) global dependencies"

# see: https://docs.npmjs.com/cli/v9/commands/npm-update?v=true#updating-globally-installed-packages
general_dependencies=(
  npm
  npm-check
  trash-cli
)

neovim_dependencies=(
  bash-language-server              # see: ...
  cssmodules-language-server        # see: ...
  dockerfile-language-server-nodejs # see: ...
  emmet-ls                          # see: ...
  neovim                            # see: ...
  pug-lint                          # see: ...
  svelte-language-server            # see: ...
  tree-sitter-cli                   # see: ...
  typescript                        # see: ...
  vscode-langservers-extracted      # see: ...
)

packages=("${general_dependencies[@]}" "${neovim_dependencies[@]}")
installed_packages=$(npm list -g --depth=0)
outdated_packages=$(npm outdated -g)

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

printf "🎉 All npm packages are installed and up to date.\n"
