# Features Directories

The new-feature template directory groups all the related files for a particular tool/use case.

## Architecture

```
{feature}/
├── config/        # Tool-specific configs to symlink
├── tests/         # Feature-specific tests
├── install.bash   # Installation logic
├── symlink.bash   # Configuration symlinking logic (if applicable)
├── uninstall.bash # Uninstallation logic
├── update.bash    # Update logic (if applicable)
├── utils.bash     # Shared utilities (optional)
└── README.md      # Feature documentation (optional)
```

## Key Principles

1. **Feature Cohesion**: Everything related to a tool lives in one folder
2. **Self-Contained**: Each feature can be understood in isolation
3. **Discoverable**: `ls features/` shows all available tools
4. **Testable**: Tests live with the code they test
5. **No Nesting**: Features are directly under `/features`, not in category subfolders

## Adding a New Feature

1. Copy the `new-feature` template directory to the root of the project and rename it
1. Update or delete each example file
1. Move or create tests in `{tool}/tests/`
1. Reference `{tool}/update.bash` in `update.bash`
1. Reference `{tool}/install.bash` in `setup.bash`
