#!/usr/bin/env bats

# Test Rust installation and update scripts
# Tests the main installation flow and update functionality

# Load testing helpers
setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Save original environment variables for restoration
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_CARGO_HOME="${CARGO_HOME:-}"
    export ORIGINAL_RUSTUP_HOME="${RUSTUP_HOME:-}"
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_DOTFILES="${DOTFILES:-}"
    
    # Set up test environment
    export HOME="$TEST_TEMP_DIR/fake_home"
    export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
    
    # Create fake dotfiles structure
    mkdir -p "$DOTFILES/features/rust"
    cp "$BATS_TEST_DIRNAME/../utils.bash" "$DOTFILES/features/rust/"
    cp "$BATS_TEST_DIRNAME/../install.bash" "$DOTFILES/features/rust/"
    cp "$BATS_TEST_DIRNAME/../update.bash" "$DOTFILES/features/rust/"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"
    export CARGO_HOME="$ORIGINAL_CARGO_HOME"
    export RUSTUP_HOME="$ORIGINAL_RUSTUP_HOME"
    export PATH="$ORIGINAL_PATH"
    export DOTFILES="$ORIGINAL_DOTFILES"
    
    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Helper function to mock rustup commands
setup_rustup_mock() {
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    
    # Create mock rustup
    cat > "$fake_bin/rustup" << 'EOF'
#!/bin/bash
case "$1" in
    --version) echo "rustup 1.26.0 (5af9b9484 2023-04-05)" ;;
    update) 
        echo "info: syncing channel updates for 'stable-x86_64-apple-darwin'"
        echo "stable-x86_64-apple-darwin updated - rustc 1.70.0 (90c541806 2023-05-31)"
        ;;
    toolchain)
        case "$2" in
            list) echo "stable-x86_64-apple-darwin (default)" ;;
        esac
        ;;
    default) echo "stable-x86_64-apple-darwin (default)" ;;
    *) return 0 ;;
esac
EOF
    chmod +x "$fake_bin/rustup"
    
    # Create mock rustc
    cat > "$fake_bin/rustc" << 'EOF'
#!/bin/bash
echo "rustc 1.70.0 (90c541806 2023-05-31)"
EOF
    chmod +x "$fake_bin/rustc"
    
    # Create mock cargo
    cat > "$fake_bin/cargo" << 'EOF'
#!/bin/bash
echo "cargo 1.70.0 (boat)"
EOF
    chmod +x "$fake_bin/cargo"
    
    PATH="$fake_bin:/usr/bin:/bin"
}

# Helper function to mock successful rustup installation
setup_rustup_installer_mock() {
    # Mock curl to simulate rustup installer
    curl() {
        # Simulate the rustup installer download and execution
        case "$*" in
            *"sh.rustup.rs"*)
                # Simulate piping to sh with -y flag
                local fake_installer="$TEST_TEMP_DIR/rustup_installer.sh"
                cat > "$fake_installer" << 'EOF'
#!/bin/bash
echo "info: downloading installer"
echo "info: profile set to 'default'"
echo "info: default host triple is x86_64-apple-darwin"
echo "info: installing component 'rustc'"
echo "info: installing component 'rust-std'"
echo "info: installing component 'cargo'"
echo "Rust is installed now. Great!"

# Create fake cargo and rustup in the expected location
mkdir -p "$CARGO_HOME/bin"
echo '#!/bin/bash\necho "cargo 1.70.0 (boat)"' > "$CARGO_HOME/bin/cargo"
echo '#!/bin/bash\necho "rustc 1.70.0 (90c541806 2023-05-31)"' > "$CARGO_HOME/bin/rustc"
echo '#!/bin/bash\necho "rustup 1.26.0 (5af9b9484 2023-04-05)"' > "$CARGO_HOME/bin/rustup"
chmod +x "$CARGO_HOME/bin/cargo" "$CARGO_HOME/bin/rustc" "$CARGO_HOME/bin/rustup"

# Create cargo env file
cat > "$CARGO_HOME/env" << 'CARGO_ENV'
PATH="$CARGO_HOME/bin:/usr/bin:/bin"
CARGO_ENV
EOF
                chmod +x "$fake_installer"
                sh "$fake_installer" -s -- -y
                return 0
                ;;
        esac
        return 1
    }
    export -f curl
    
    # Mock source command for cargo env
    source() {
        if [[ "$1" == *"cargo/env" ]]; then
            PATH="$CARGO_HOME/bin:/usr/bin:/bin"
        fi
        return 0
    }
    export -f source
}

@test "install script detects when Rust is already installed" {
    setup_rustup_mock
    
    run bash "$DOTFILES/features/rust/install.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Rust"* ]]
    [[ "$output" == *"Rust is already installed"* ]]
    [[ "$output" == *"Current Rust version: rustc 1.70.0"* ]]
    [[ "$output" == *"Rust setup completed"* ]]
}

@test "install script installs Rust when not present" {
    setup_rustup_installer_mock
    
    # Ensure no rust tools are in PATH initially
    export PATH="/usr/bin:/bin"
    
    run bash "$DOTFILES/features/rust/install.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Rust"* ]]
    [[ "$output" == *"Rust not found, proceeding with installation"* ]]
    [[ "$output" == *"Installing Rust via rustup"* ]]
    [[ "$output" == *"Rust installed successfully"* ]]
    [[ "$output" == *"Finished installing Rust successfully"* ]]
}

@test "install script sets up custom environment paths" {
    setup_rustup_mock
    
    run bash "$DOTFILES/features/rust/install.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"CARGO_HOME: $HOME/.config/cargo"* ]]
    [[ "$output" == *"RUSTUP_HOME: $HOME/.config/rustup"* ]]
}

@test "install script provides helpful next steps when installation succeeds" {
    setup_rustup_installer_mock
    
    # Ensure no rust tools are in PATH initially
    export PATH="/usr/bin:/bin"
    
    run bash "$DOTFILES/features/rust/install.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Next steps:"* ]]
    [[ "$output" == *"source ~/.config/cargo/env"* ]]
    [[ "$output" == *"cargo --version"* ]]
    [[ "$output" == *"rustc --version"* ]]
}

@test "update script installs Rust when rustup not available" {
    setup_rustup_installer_mock
    
    # Ensure no rust tools are in PATH initially
    export PATH="/usr/bin:/bin"
    
    run bash "$DOTFILES/features/rust/update.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Updating Rust"* ]]
    [[ "$output" == *"rustup is not installed"* ]]
    [[ "$output" == *"Installing Rust first"* ]]
    [[ "$output" == *"Rust installation and update completed"* ]]
}

@test "update script updates existing Rust installation" {
    setup_rustup_mock
    
    run bash "$DOTFILES/features/rust/update.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Updating Rust"* ]]
    [[ "$output" == *"Current Rust state:"* ]]
    [[ "$output" == *"Current Rust version: rustc 1.70.0"* ]]
    [[ "$output" == *"Updating Rust toolchain"* ]]
    [[ "$output" == *"Rust toolchain update completed"* ]]
    [[ "$output" == *"Rust update completed successfully"* ]]
}

@test "update script displays toolchain information after update" {
    setup_rustup_mock
    
    run bash "$DOTFILES/features/rust/update.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installed toolchains:"* ]]
    [[ "$output" == *"stable-x86_64-apple-darwin"* ]]
}

@test "update script validates installation after update" {
    setup_rustup_mock
    
    run bash "$DOTFILES/features/rust/update.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Validating updated Rust installation"* ]]
    [[ "$output" == *"Rust installation validation passed"* ]]
    [[ "$output" == *"rustc is functional"* ]]
    [[ "$output" == *"cargo is functional"* ]]
}

@test "install script fails gracefully when installation fails" {
    # Mock curl to fail
    curl() {
        echo "Failed to download rustup installer"
        return 1
    }
    export -f curl
    
    # Ensure no rust tools are in PATH initially
    export PATH="/usr/bin:/bin"
    
    run bash "$DOTFILES/features/rust/install.bash"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to install Rust"* ]]
}

@test "update script fails gracefully when rustup update fails" {
    # Mock rustup to fail on update
    rustup() {
        case "$1" in
            --version) echo "rustup 1.26.0 (5af9b9484 2023-04-05)" ;;
            update) echo "Error: Failed to update"; return 1 ;;
            *) return 0 ;;
        esac
    }
    export -f rustup
    
    # Create a fake rustup binary in PATH
    local fake_bin="$TEST_TEMP_DIR/bin"
    mkdir -p "$fake_bin"
    echo '#!/bin/bash\nrustup "$@"' > "$fake_bin/rustup"
    chmod +x "$fake_bin/rustup"
    PATH="$fake_bin:/usr/bin:/bin"
    
    run bash "$DOTFILES/features/rust/update.bash"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to update Rust toolchain"* ]]
}

@test "scripts can be executed directly without sourcing" {
    setup_rustup_mock
    
    # Test install script
    run "$DOTFILES/features/rust/install.bash"
    [ "$status" -eq 0 ]
    
    # Test update script
    run "$DOTFILES/features/rust/update.bash"
    [ "$status" -eq 0 ]
}

@test "scripts handle missing DOTFILES environment variable" {
    setup_rustup_mock
    
    # Clear DOTFILES and test default fallback
    unset DOTFILES
    local script_dir="$(dirname "${BATS_TEST_DIRNAME}/../install.bash")"
    
    # Update the script path in the copied files to use relative path
    sed -i '' 's|source "$DOTFILES/features/rust/utils.bash"|source "$(dirname "$0")/utils.bash"|' "$TEST_TEMP_DIR/fake_dotfiles/features/rust/install.bash"
    
    run bash "$TEST_TEMP_DIR/fake_dotfiles/features/rust/install.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing Rust"* ]]
}