#!/usr/bin/env bash

# GitHub utility functions for installation scripts
# Provides reusable functionality for GitHub SSH setup and verification

set -euo pipefail

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