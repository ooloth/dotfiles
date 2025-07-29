# Yazi Feature

This feature manages Yazi file manager flavors installation.

## What it does

1. **Machine Detection**: Skips installation on work machines
2. **Flavors Installation**: Clones yazi-rs/flavors repository
3. **Theme Configuration**: Symlinks catppuccin-mocha theme

## Dependencies

- **Core Detection**: Uses `core/detection/machine.bash` for machine type detection
- **Git**: Required for cloning the flavors repository

## Installation

```bash
./features/yazi/install.bash
```

## Configuration

No configuration files are directly managed, but creates symlinks to:
- `~/.config/yazi/flavors/catppuccin-mocha.yazi`

## Testing

```bash
bats features/yazi/tests/
```