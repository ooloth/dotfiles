#!/usr/bin/env zsh

packages=(
  aocrunner
  bash-language-server # for neovim
  cssmodules-language-server # for neovim
  dockerfile-language-server-nodejs # for neovim
  emmet-ls # for neovim
  neovim # for neovim
  npm
  npm-check
  pug-lint # for neovim
  svelte-language-server # for neovim
  tree-sitter-cli # for neovim
  typescript # for neovim
  vscode-langservers-extracted # for neovim
)

installed_packages=$(npm list -g --depth=0)
outdated_packages=$(npm outdated -g)

is_package_installed() {
  local package="$1"
  echo "$installed_packages" | grep -q " ${package}@"
}

is_package_outdated() {
  local package="$1"
  echo "$outdated_packages" | grep -q "^${package}"
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
else
  echo "🎉 All npm packages are installed and up to date."
fi