# Installation Script Testing Framework

This directory contains the testing framework and utilities for testing dotfiles installation scripts.

## Overview

The installation testing framework provides:

- **Environment Isolation**: Test scripts run in isolated environments that don't affect the host system
- **Command Mocking**: Mock external dependencies like brew, git, ssh-keygen, curl, etc.
- **Installation Assertions**: Specialized assertions for validating installation outcomes
- **Script Execution**: Safe execution of installation scripts with output capture

## Directory Structure

```
test/install/
├── lib/
│   ├── install-test-utils.zsh   # Core testing utilities for installation scripts
│   ├── install-mocks.zsh        # Mocking framework for external commands
├── test-install-framework.zsh   # Tests for the testing framework itself
├── test-simple-framework.zsh    # Simple framework validation tests
└── README.md                    # This documentation
```

## Usage

### Basic Test Setup

```bash
#!/usr/bin/env zsh

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/install/lib/install-test-utils.zsh"
source "$DOTFILES/test/install/lib/install-mocks.zsh"

test_homebrew_installation() {
    test_suite "Homebrew Installation"
    
    # Set up isolated test environment
    setup_install_test_environment
    init_install_mocking
    
    test_case "Should install Homebrew successfully"
    
    # Mock successful Homebrew installation
    mock_homebrew_success
    
    # Run the installation script
    run_install_script "$DOTFILES/bin/install/2-homebrew.zsh"
    local exit_code=$(get_install_exit_code)
    
    # Verify installation succeeded
    assert_installation_successful "homebrew.zsh" "$exit_code"
    
    # Verify expected commands were called
    verify_homebrew_called
    
    # Verify output contains expected messages
    assert_install_output_contains "Homebrew installed successfully"
    
    # Clean up
    cleanup_install_mocking
    cleanup_install_test_environment
    
    test_suite_end
}
```

### Available Mocking Functions

- `mock_homebrew_success()` / `mock_homebrew_failure()`
- `mock_ssh_key_success()` / `mock_ssh_key_failure()`
- `mock_network_failure()`
- `mock_permission_failure()`

### Available Assertions

- `assert_installation_successful(script_name, exit_code)`
- `assert_installation_failed(script_name, exit_code)`
- `assert_command_executed(command)`
- `assert_command_not_executed(command)`
- `assert_file_created(file_path)`
- `assert_symlink_created(link_path, target_path)`
- `assert_directory_created(dir_path)`
- `assert_install_output_contains(text)`
- `assert_install_output_not_contains(text)`

### Verification Functions

- `verify_homebrew_called()` / `verify_homebrew_not_called()`
- `verify_ssh_keygen_called()` / `verify_ssh_keygen_not_called()`
- `verify_git_called()`

## Test Environment

When `setup_install_test_environment()` is called, the following test directories are created:

- `$INSTALL_TEST_HOME` - Mock home directory (`~`)
- `$INSTALL_TEST_LOCAL` - Mock `/usr/local` directory
- `$INSTALL_TEST_HOMEBREW_DIR` - Mock Homebrew directory
- `$INSTALL_TEST_SSH_DIR` - Mock SSH directory
- `$INSTALL_TEST_CONFIG_DIR` - Mock configuration directory

## Command Mocking

The framework mocks common installation tools:

**Homebrew Commands:**
- `brew`, `brew install`, `brew bundle`, `brew doctor`, etc.

**SSH Commands:**
- `ssh-keygen`, `ssh`, `ssh-add`

**Git Commands:**
- `git`, `git clone`, `git config`

**System Commands:**
- `curl`, `wget`, `tar`, `unzip`, `sudo`
- `xcode-select`, `npm`, `pnpm`, `fnm`

**Python/Rust Tools:**
- `python3`, `pip3`, `uv`, `rustup`, `cargo`

## Running Tests

Run all installation tests:
```bash
./test/run-tests.zsh test/install/
```

Run a specific test:
```bash
./test/install/test-homebrew.zsh
```

## Framework Testing

The framework itself is tested in `test-install-framework.zsh` to ensure:

- Environment setup works correctly
- Command mocking functions properly
- Assertions validate expected behaviors
- Script execution captures output and exit codes
- Integration with existing utilities (dry-run, error handling) works

## Next Steps

This framework will be used to create comprehensive tests for:

1. **PR 7**: Homebrew installation script testing
2. **PR 8**: SSH setup and GitHub authentication testing
3. **PR 9**: Node.js and package manager testing
4. **PR 10**: Additional installation script testing (shell, symlinks, macOS)

Each PR will focus on testing a specific installation component using this shared framework.