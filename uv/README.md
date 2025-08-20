# UV Feature

This feature manages UV (Python package manager) installation.

## What it does

1. **UV Installation**: Installs UV using Homebrew
2. **Version Verification**: Confirms installation and displays version

## Dependencies

- **Homebrew**: Used to install UV

## Installation

```bash
./uv/install.bash
```

## Configuration

No configuration files are managed by this feature.

## Testing

```bash
bats uv/tests/
```

## References

- [UV Documentation](https://docs.astral.sh/uv/)
