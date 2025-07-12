#!/usr/bin/env zsh

# Installation-specific mocking utilities
# Provides mocks for common installation tools and commands

# Source base mocking framework
source "$DOTFILES/test/lib/mock.zsh"

# Initialize installation mocks
init_install_mocking() {
    init_mocking
    
    # Create installation-specific mock directories within the test temp dir
    export MOCK_HOMEBREW_DIR="$TEST_TEMP_DIR/mock/homebrew"
    export MOCK_SSH_DIR="$TEST_TEMP_DIR/mock/ssh"
    export MOCK_GIT_DIR="$TEST_TEMP_DIR/mock/git"
    
    mkdir -p "$MOCK_HOMEBREW_DIR"
    mkdir -p "$MOCK_SSH_DIR"
    mkdir -p "$MOCK_GIT_DIR"
    
    # Setup installation tool mocks
    setup_homebrew_mocks
    setup_ssh_mocks
    setup_git_mocks
    setup_system_mocks
}

# Cleanup installation mocks
cleanup_install_mocking() {
    cleanup_mocking
    
    unset MOCK_HOMEBREW_DIR
    unset MOCK_SSH_DIR
    unset MOCK_GIT_DIR
}

# Setup Homebrew command mocks
setup_homebrew_mocks() {
    # Mock brew command
    mock_command "brew" 0 ""
    
    # Mock common brew subcommands
    mock_command "brew --version" 0 "Homebrew 4.0.0"
    mock_command "brew install" 0 "Installing packages..."
    mock_command "brew bundle" 0 "Installing from Brewfile..."
    mock_command "brew list" 0 ""
    mock_command "brew doctor" 0 "Your system is ready to brew."
    mock_command "brew update" 0 "Already up-to-date."
    mock_command "brew upgrade" 0 "No packages to upgrade."
    
    # Mock Homebrew installation detection
    mock_command "which brew" 0 "/opt/homebrew/bin/brew"
    mock_command "command -v brew" 0 "/opt/homebrew/bin/brew"
}

# Setup SSH command mocks
setup_ssh_mocks() {
    # Mock ssh-keygen command
    mock_command "ssh-keygen" 0 "Generating public/private ed25519 key pair."
    mock_command "ssh-keygen -t ed25519" 0 "Generating public/private ed25519 key pair."
    mock_command "ssh-keygen -t rsa" 0 "Generating public/private rsa key pair."
    
    # Mock ssh command
    mock_command "ssh" 0 ""
    mock_command "ssh -T git@github.com" 0 "Hi username! You've successfully authenticated"
    
    # Mock ssh-add command
    mock_command "ssh-add" 0 "Identity added"
    mock_command "ssh-add -K" 0 "Identity added to keychain"
    
    # Mock SSH configuration commands
    mock_command "chmod 600" 0 ""
    mock_command "chmod 644" 0 ""
    mock_command "chmod 700" 0 ""
}

# Setup Git command mocks
setup_git_mocks() {
    # Mock git command
    mock_command "git" 0 ""
    mock_command "git --version" 0 "git version 2.40.0"
    mock_command "git config" 0 ""
    mock_command "git clone" 0 "Cloning into repository..."
    mock_command "git pull" 0 "Already up to date."
    mock_command "git status" 0 "On branch main. Working tree clean."
    
    # Mock GitHub CLI
    mock_command "gh" 0 ""
    mock_command "gh --version" 0 "gh version 2.20.0"
    mock_command "gh auth login" 0 "Authentication successful"
    mock_command "gh auth status" 0 "Logged in to github.com"
}

# Setup system command mocks
setup_system_mocks() {
    # Mock curl for downloads
    mock_command "curl" 0 "Download successful"
    mock_command "curl -fsSL" 0 "Download successful"
    mock_command "curl -o" 0 "Download successful"
    
    # Mock wget for downloads
    mock_command "wget" 0 "Download successful"
    
    # Mock tar for extractions
    mock_command "tar" 0 ""
    mock_command "tar -xzf" 0 "Extraction successful"
    
    # Mock unzip for extractions
    mock_command "unzip" 0 "Archive extracted"
    
    # Mock system commands
    mock_command "sudo" 0 ""
    mock_command "xcode-select --install" 0 "Command Line Tools installed"
    mock_command "xcode-select -p" 0 "/Applications/Xcode.app/Contents/Developer"
    
    # Mock package managers
    mock_command "npm" 0 ""
    mock_command "npm install" 0 "Package installed"
    mock_command "npm --version" 0 "8.19.0"
    
    mock_command "pnpm" 0 ""
    mock_command "pnpm install" 0 "Package installed"
    mock_command "pnpm --version" 0 "7.18.0"
    
    # Mock Node.js version manager (fnm)
    mock_command "fnm" 0 ""
    mock_command "fnm install" 0 "Node.js installed"
    mock_command "fnm use" 0 "Using Node.js version"
    mock_command "fnm --version" 0 "fnm 1.33.0"
    
    # Mock Python tools
    mock_command "python3" 0 "Python 3.11.0"
    mock_command "pip3" 0 ""
    mock_command "uv" 0 ""
    
    # Mock Rust tools
    mock_command "rustup" 0 ""
    mock_command "cargo" 0 ""
    mock_command "rustc --version" 0 "rustc 1.70.0"
}

# Mock successful Homebrew installation
mock_homebrew_success() {
    setup_homebrew_mocks
    
    # Create mock Homebrew directory structure
    mkdir -p "$MOCK_HOMEBREW_DIR/bin"
    mkdir -p "$MOCK_HOMEBREW_DIR/etc"
    
    # Create mock brew binary
    printf '#!/bin/bash\necho "Homebrew mocked successfully"' > "$MOCK_HOMEBREW_DIR/bin/brew"
    chmod +x "$MOCK_HOMEBREW_DIR/bin/brew"
}

# Mock failed Homebrew installation
mock_homebrew_failure() {
    # Mock brew command with failure
    mock_command "brew" 1 "Error: Homebrew installation failed"
    mock_command "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" 1 "Download failed"
}

# Mock missing Homebrew (not installed)
mock_homebrew_missing() {
    # Mock commands to indicate Homebrew is not installed
    mock_command "command -v brew" 1 ""
    mock_command "which brew" 1 ""
    mock_command "brew" 127 "zsh: command not found: brew"
    mock_command "brew --version" 127 "zsh: command not found: brew"
}

# Mock successful SSH key generation
mock_ssh_key_success() {
    setup_ssh_mocks
    
    # Create mock SSH directory and keys
    mkdir -p "$MOCK_SSH_DIR"
    echo "mock-private-key" > "$MOCK_SSH_DIR/id_ed25519"
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... mock-public-key" > "$MOCK_SSH_DIR/id_ed25519.pub"
    chmod 600 "$MOCK_SSH_DIR/id_ed25519"
    chmod 644 "$MOCK_SSH_DIR/id_ed25519.pub"
    
    # Mock successful GitHub authentication
    mock_command "ssh -T git@github.com" 0 "Hi testuser! You've successfully authenticated, but GitHub does not provide shell access."
}

# Mock failed SSH key generation
mock_ssh_key_failure() {
    # Mock ssh-keygen failure
    mock_command "ssh-keygen" 1 "Error: Failed to generate SSH key"
    mock_command "ssh -T git@github.com" 255 "Permission denied (publickey)."
}

# Mock network connectivity issues
mock_network_failure() {
    # Mock network-dependent commands with failures
    mock_command "curl" 6 "Could not resolve host"
    mock_command "wget" 4 "Network unreachable"
    mock_command "git clone" 128 "fatal: unable to access repository"
    mock_command "brew update" 1 "Error: Failed to connect to GitHub"
    mock_command "ssh -T git@github.com" 255 "ssh: connect to host github.com port 22: Network is unreachable"
}

# Mock permission issues
mock_permission_failure() {
    # Mock permission-denied errors
    mock_command "mkdir" 1 "mkdir: Permission denied"
    mock_command "chmod" 1 "chmod: Operation not permitted"
    mock_command "ln -sf" 1 "ln: Permission denied"
    mock_command "sudo" 1 "sudo: Authentication failure"
}

# Verify that specific installation tools were called
verify_homebrew_called() {
    assert_command_executed "brew" "Homebrew should have been used during installation"
}

verify_ssh_keygen_called() {
    assert_command_executed "ssh-keygen" "SSH key generation should have been called"
}

verify_git_called() {
    assert_command_executed "git" "Git should have been used during installation"
}

# Verify that installation completed without calling specific tools
verify_homebrew_not_called() {
    assert_command_not_executed "brew" "Homebrew should NOT have been used"
}

verify_ssh_keygen_not_called() {
    assert_command_not_executed "ssh-keygen" "SSH key generation should NOT have been called"
}