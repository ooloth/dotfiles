#!/usr/bin/env bash
# Example script showing how to use npm-utils.bash for updating packages
# This demonstrates the pattern that update scripts can follow

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities
source "$SCRIPT_DIR/lib/npm-utils.bash"

echo "✨ Updating Node $(get_node_version) global dependencies"

# Validate environment
if ! validate_npm_environment; then
  exit 1
fi

# Get all dependencies
mapfile -t packages < <(get_all_npm_dependencies)

echo "Checking ${#packages[@]} packages for updates..."

# Analyze what needs to be done
analysis_output=$(analyze_package_requirements "${packages[@]}")

# Parse the analysis results
packages_to_add=()
packages_to_update=()

while IFS= read -r line; do
  if [[ "$line" == TO_ADD:* ]]; then
    # Convert space-separated string to array
    IFS=' ' read -ra packages_to_add <<< "${line#TO_ADD:}"
  elif [[ "$line" == TO_UPDATE:* ]]; then
    # Convert space-separated string to array
    IFS=' ' read -ra packages_to_update <<< "${line#TO_UPDATE:}"
  fi
done <<< "$analysis_output"

# Report what will be done
echo ""
for package in "${packages_to_add[@]}"; do
  printf "📦 Installing %s\n" "$package"
done

for package in "${packages_to_update[@]}"; do
  printf "🚀 Updating %s\n" "$package"
done

# Install and update packages
if [[ ${#packages_to_add[@]} -gt 0 ]] || [[ ${#packages_to_update[@]} -gt 0 ]]; then
  all_packages=("${packages_to_add[@]}" "${packages_to_update[@]}")
  if install_and_update_npm_packages "${all_packages[@]}"; then
    echo "🎉 All npm packages are installed and up to date."
  else
    echo "❌ Failed to update npm packages"
    exit 1
  fi
else
  echo "🎉 All npm packages are already installed and up to date."
fi