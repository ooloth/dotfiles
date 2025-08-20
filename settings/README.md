# Settings Feature

This feature manages macOS system settings and preferences configuration.

## Purpose

Configures various macOS system preferences to improve the user experience and productivity.

## Files

- `install.bash` - Main installation script
- `utils.bash` - Utility functions for settings configuration
- `README.md` - This documentation

## Usage

Configure macOS system settings:
```bash
bash settings/install.bash
```

## What it does

### General Settings
- Expand save dialog by default
- Enable full keyboard access for all controls
- Enable subpixel font rendering on non-Apple LCDs

### Finder Settings
- Show all filename extensions
- Hide hidden files by default
- Use current directory as default search scope
- Show Path bar and Status bar
- Show the ~/Library folder

### Safari Settings
- Enable Safari's debug menu (may not work on newer macOS versions)

## Dependencies

- macOS operating system
- `defaults` command (built into macOS)
- `chflags` command (built into macOS)

## Platform Support

This feature only runs on macOS systems and will skip installation on other platforms.
