# Content Feature

This feature manages the content repository installation and setup.

## Purpose

Handles cloning and managing the separate content repository that contains blog posts, articles, and other content files.

## Files

- `install.bash` - Main installation script
- `utils.bash` - Utility functions for content repository management
- `README.md` - This documentation

## Usage

Install content repository:
```bash
bash features/content/install.bash
```

## What it does

- Clones the `ooloth/content` repository to `~/Repos/ooloth/content`
- Uses SSH if available, falls back to HTTPS
- Skips installation if repository already exists

## Dependencies

- Git
- Network connectivity to GitHub
- SSH key configured (optional, but recommended)