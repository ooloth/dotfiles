#!/usr/bin/env bats

# Node.js update script tests
# Tests the main Node.js update workflow including npm package management
# Load BATS test helpers
load "../../../core/testing/bats-helper.bash"

# Load the update script
load "../update.bash"

# Test setup and teardown
setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment variables
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
    
    # Set test environment
    export DOTFILES="$TEST_TEMP_DIR/dotfiles"
    mkdir -p "$DOTFILES/features/node"
    
    # Create a mock utils.bash file
    cat > "$DOTFILES/features/node/utils.bash" << 'EOF'
#!/usr/bin/env bash
get_current_node_version() { echo "v20.9.0"; }
get_latest_node_version() { echo "v20.10.0"; }
is_node_version_installed() { [[ "$1" == "v20.10.0" ]] && return 1 || return 0; }
install_node_version() { return 0; }
set_default_node_version() { return 0; }
activate_node_version() { return 0; }
EOF
}

teardown() {
    # Restore original environment
    export PATH="$ORIGINAL_PATH"
    export DOTFILES="$ORIGINAL_DOTFILES"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Unit Tests for is_npm_package_installed function

@test "is_npm_package_installed returns 0 when package is installed" {
    # Create a fake npm command that lists packages including git
    echo '#!/bin/bash
if [[ "$1" == "list" && "$2" == "-g" && "$3" == "--depth=0" ]]; then
    echo "├── npm@10.2.0"
    echo "└── trash-cli@5.0.0"
fi' > "$TEST_TEMP_DIR/npm"
    chmod +x "$TEST_TEMP_DIR/npm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run is_npm_package_installed "npm"
    [ "$status" -eq 0 ]
}

@test "is_npm_package_installed returns 1 when package is not installed" {
    # Create a fake npm command that lists packages NOT including target
    echo '#!/bin/bash
if [[ "$1" == "list" && "$2" == "-g" && "$3" == "--depth=0" ]]; then
    echo "├── npm@10.2.0"
    echo "└── trash-cli@5.0.0"
fi' > "$TEST_TEMP_DIR/npm"
    chmod +x "$TEST_TEMP_DIR/npm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run is_npm_package_installed "typescript"
    [ "$status" -eq 1 ]
}

@test "is_npm_package_installed returns 1 when npm list fails" {
    # Create a fake npm command that fails
    echo '#!/bin/bash
echo "Error: npm command failed" >&2
exit 1' > "$TEST_TEMP_DIR/npm"
    chmod +x "$TEST_TEMP_DIR/npm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run is_npm_package_installed "npm"
    [ "$status" -eq 1 ]
}

@test "is_npm_package_installed requires package name argument" {
    run is_npm_package_installed ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Package name is required"* ]]
}

# Unit Tests for is_npm_package_outdated function

@test "is_npm_package_outdated returns 0 when package is outdated" {
    # Create a fake npm command that lists outdated packages
    echo '#!/bin/bash
if [[ "$1" == "outdated" && "$2" == "-g" ]]; then
    echo "Package  Current  Wanted  Latest  Location"
    echo "npm      10.1.0   10.2.0  10.2.0  global"
fi' > "$TEST_TEMP_DIR/npm"
    chmod +x "$TEST_TEMP_DIR/npm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run is_npm_package_outdated "npm"
    [ "$status" -eq 0 ]
}

@test "is_npm_package_outdated returns 1 when package is up to date" {
    # Create a fake npm command that shows no outdated packages
    echo '#!/bin/bash
if [[ "$1" == "outdated" && "$2" == "-g" ]]; then
    echo "Package  Current  Wanted  Latest  Location"
    # No packages listed = all up to date
fi' > "$TEST_TEMP_DIR/npm"
    chmod +x "$TEST_TEMP_DIR/npm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run is_npm_package_outdated "npm"
    [ "$status" -eq 1 ]
}

@test "is_npm_package_outdated returns 1 when npm outdated fails" {
    # Create a fake npm command that fails
    echo '#!/bin/bash
echo "Error: npm command failed" >&2
exit 1' > "$TEST_TEMP_DIR/npm"
    chmod +x "$TEST_TEMP_DIR/npm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run is_npm_package_outdated "npm"
    [ "$status" -eq 1 ]
}

# Unit Tests for update_node_version function

@test "update_node_version succeeds when new version is available" {
    # Create fake commands
    echo '#!/bin/bash
echo "fnm command executed with args: $@"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run update_node_version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Node.js v20.10.0"* ]]
    [[ "$output" == *"Node.js v20.10.0 set as default and activated"* ]]
}

@test "update_node_version succeeds when already on latest version" {
    # Create fake commands
    echo '#!/bin/bash
echo "fnm command executed with args: $@"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    # Override utils to show latest version is already installed
    cat > "$DOTFILES/features/node/utils.bash" << 'EOF'
#!/usr/bin/env bash
get_current_node_version() { echo "v20.10.0"; }
get_latest_node_version() { echo "v20.10.0"; }
is_node_version_installed() { return 0; }
EOF
    
    run update_node_version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Already running the latest Node.js version (v20.10.0)"* ]]
}

@test "update_node_version returns 1 when version detection fails" {
    # Override utils to make version detection fail
    cat > "$DOTFILES/features/node/utils.bash" << 'EOF'
#!/usr/bin/env bash
get_current_node_version() { echo "v20.9.0"; }
get_latest_node_version() { return 1; }
EOF
    
    run update_node_version
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to determine latest Node.js version"* ]]
}

# Unit Tests for update_npm_packages function

@test "update_npm_packages succeeds when npm is available" {
    # Create fake npm command that works
    echo '#!/bin/bash
if [[ "$1" == "list" && "$2" == "-g" ]]; then
    echo "└── npm@10.2.0"
elif [[ "$1" == "outdated" && "$2" == "-g" ]]; then
    # No outdated packages
    echo ""
elif [[ "$1" == "install" && "$2" == "-g" ]]; then
    echo "Package installation completed"
fi' > "$TEST_TEMP_DIR/npm"
    chmod +x "$TEST_TEMP_DIR/npm"
    
    # Create fake node command for version display
    echo '#!/bin/bash
if [[ "$1" == "--version" ]]; then
    echo "v20.10.0"
fi' > "$TEST_TEMP_DIR/node"
    chmod +x "$TEST_TEMP_DIR/node"
    
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run update_npm_packages
    [ "$status" -eq 0 ]
    [[ "$output" == *"Updating Node.js"* ]]
    [[ "$output" == *"All npm packages are already up to date"* ]]
}

@test "update_npm_packages returns 1 when npm is not available" {
    # Ensure npm is not in PATH
    PATH="/usr/bin:/bin"
    
    run update_npm_packages
    [ "$status" -eq 1 ]
    [[ "$output" == *"npm is not available"* ]]
}

@test "update_npm_packages installs missing packages" {
    # Create fake npm command that shows missing packages
    echo '#!/bin/bash
if [[ "$1" == "list" && "$2" == "-g" ]]; then
    echo "└── npm@10.2.0"  # Only npm installed
elif [[ "$1" == "outdated" && "$2" == "-g" ]]; then
    echo ""  # No outdated packages
elif [[ "$1" == "install" && "$2" == "-g" ]]; then
    echo "Installing packages: $@"
    echo "Package installation completed"
fi' > "$TEST_TEMP_DIR/npm"
    chmod +x "$TEST_TEMP_DIR/npm"
    
    # Create fake node command for version display
    echo '#!/bin/bash
if [[ "$1" == "--version" ]]; then
    echo "v20.10.0"
fi' > "$TEST_TEMP_DIR/node"
    chmod +x "$TEST_TEMP_DIR/node"
    
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run update_npm_packages
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing @anthropic-ai/claude-code"* ]]
    [[ "$output" == *"Installing trash-cli"* ]]
    [[ "$output" == *"npm packages updated successfully"* ]]
}

# Integration Tests for main function

@test "main returns 1 when fnm is not available" {
    # Ensure fnm is not in PATH
    PATH="/usr/bin:/bin"
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"fnm (Fast Node Manager) is not installed"* ]]
}

@test "main succeeds when fnm and npm are available" {
    # Create fake commands
    echo '#!/bin/bash
echo "fnm command executed"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    
    echo '#!/bin/bash
if [[ "$1" == "list" && "$2" == "-g" ]]; then
    echo "└── npm@10.2.0"
elif [[ "$1" == "outdated" && "$2" == "-g" ]]; then
    echo ""
elif [[ "$1" == "install" ]]; then
    echo "Package installation completed"
fi' > "$TEST_TEMP_DIR/npm"
    chmod +x "$TEST_TEMP_DIR/npm"
    
    echo '#!/bin/bash
if [[ "$1" == "--version" ]]; then
    echo "v20.10.0"
fi' > "$TEST_TEMP_DIR/node"
    chmod +x "$TEST_TEMP_DIR/node"
    
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"Updating Node.js and npm packages"* ]]
    [[ "$output" == *"All Node.js updates completed successfully"* ]]
}

@test "main returns 1 when node update fails" {
    # Create fake fnm command
    echo '#!/bin/bash
echo "fnm command executed"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    # Override utils to make update fail
    cat > "$DOTFILES/features/node/utils.bash" << 'EOF'
#!/usr/bin/env bash
get_current_node_version() { echo "v20.9.0"; }
get_latest_node_version() { return 1; }
EOF
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"Node.js update failed"* ]]
}

@test "main returns 1 when npm update fails" {
    # Create fake fnm command
    echo '#!/bin/bash
echo "fnm command executed"' > "$TEST_TEMP_DIR/fnm"
    chmod +x "$TEST_TEMP_DIR/fnm"
    PATH="$TEST_TEMP_DIR:/usr/bin:/bin"
    
    # Don't create npm command (will fail)
    
    run main
    [ "$status" -eq 1 ]
    [[ "$output" == *"npm packages update failed"* ]]
}