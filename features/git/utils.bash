#!/usr/bin/env bash

# Git and GitHub utility functions for installation scripts
# Provides reusable functionality for Git configuration and GitHub SSH setup

set -euo pipefail

# ============================================================================
# Git Configuration Functions
# ============================================================================

# Configure global git settings from a config file
configure_git_global() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        echo "❌ Config file not found: $config_file"
        return 1
    fi
    
    # Apply settings from config file using include.path
    git config --global include.path "$config_file"
    return $?
}

# Configure work-specific git settings
configure_git_work() {
    local work_config="$1"
    
    if [[ ! -f "$work_config" ]]; then
        echo "❌ Work config file not found: $work_config"
        return 1
    fi
    
    # Apply work overrides for specific directories
    git config --global includeIf."gitdir:~/Repos/recursionpharma/".path "$work_config"
    return $?
}

# Configure global git ignore file
configure_git_ignore() {
    local ignore_file="$1"
    
    if [[ ! -f "$ignore_file" ]]; then
        echo "❌ Ignore file not found: $ignore_file"
        return 1
    fi
    
    git config --global core.excludesfile "$ignore_file"
    return $?
}

# Validate git configuration was applied correctly
validate_git_configuration() {
    local has_errors=false
    
    # Check if critical settings are present
    if ! git config --global user.name >/dev/null 2>&1; then
        echo "❌ Git user.name not configured"
        has_errors=true
    fi
    
    if ! git config --global user.email >/dev/null 2>&1; then
        echo "❌ Git user.email not configured"
        has_errors=true
    fi
    
    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# GitHub SSH Functions
# ============================================================================

# Test SSH connection to GitHub
github_ssh_connection_works() {
    ssh -T git@github.com >/dev/null 2>&1
}

# Check if SSH keys exist and are non-empty
ssh_keys_exist() {
    local ssh_dir="${HOME}/.ssh"
    local private_key="${ssh_dir}/id_rsa"
    local public_key="${ssh_dir}/id_rsa.pub"
    
    [[ -s "$private_key" && -s "$public_key" ]]
}

# Check if SSH keys are loaded in ssh-agent
ssh_keys_in_agent() {
    ssh-add -l >/dev/null 2>&1
}

# Get the current git remote URL for a repository
get_git_remote_url() {
    local repo_dir="$1"
    
    if [[ ! -d "$repo_dir" ]]; then
        return 1
    fi
    
    (
        cd "$repo_dir"
        git config --get remote.origin.url 2>/dev/null
    )
}

# Check if a git remote URL uses HTTPS
is_https_remote() {
    local remote_url="$1"
    [[ "$remote_url" == https://github.com/* ]]
}

# Convert HTTPS GitHub URL to SSH format
convert_https_to_ssh() {
    local https_url="$1"
    
    if [[ "$https_url" == https://github.com/* ]]; then
        echo "git@github.com:${https_url#https://github.com/}"
    else
        echo "$https_url"
    fi
}

# Set git remote URL for a repository
set_git_remote_url() {
    local repo_dir="$1"
    local new_url="$2"
    
    if [[ ! -d "$repo_dir" ]]; then
        return 1
    fi
    
    (
        cd "$repo_dir"
        git remote set-url origin "$new_url"
    )
}