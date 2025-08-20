# macOS Feature

This feature manages macOS system software updates with machine detection.

## What it does

1. **Machine Detection**: Skips updates on work machines to avoid disruption
2. **System Updates**: Runs macOS software updates with automatic restart
3. **License Agreement**: Automatically agrees to software license terms

## Dependencies

- **Common Detection**: Uses `@common/detection/machine.bash` for machine type detection
- **macOS**: Only runs on macOS systems
- **Admin Access**: Requires sudo privileges for software updates

## Usage

```bash
./macos/update.bash
```

## Configuration

No configuration files are managed by this feature.

## Testing

```bash
bats macos/tests/
```

## Note

This feature only provides an update script, no installation script is needed as macOS is the base system.

