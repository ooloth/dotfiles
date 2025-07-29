# Content Feature

This feature handles the installation and management of the content creation tools repository.

## Purpose

Clones the `ooloth/content` repository which contains content creation tools and utilities.

## Files

- `install.bash` - Main installation script
- `utils.bash` - Utility functions for repository management
- `README.md` - This documentation

## Usage

Install the content repository:
```bash
bash features/content/install.bash
```

## What it does

1. Checks if the content repository is already cloned at `~/Repos/ooloth/content`
2. Creates the parent directory if needed
3. Clones the repository using SSH authentication
4. Provides clear feedback on installation status

## Dependencies

- Git must be installed and configured
- SSH key must be set up for GitHub access
- Network connectivity to GitHub