# Tools Directories

The @new template directory groups all the related files for a particular tool/use case.

## Architecture

```
{tool}/
├── config/                # Configuration files
├── shell/
│   ├── aliases.zsh        # Shell aliases
│   ├── integration.zsh    # Shell integration logic
│   └── variables.zsh      # Shell environment variables
├── symlinks/
│   ├── link.bash          # Symlink configuration files
│   └── unlink.bash        # Clean up symlinked files
├── install.bash           # Installation logic
├── uninstall.bash         # Uninstallation logic
├── update.bash            # Update logic (optional)
├── utils.bash             # Shared utilities (optional)
└── README.md              # Tool documentation (optional)
```

## Key Principles

1. **Feature Cohesion**: Everything related to a tool lives in one folder
2. **Self-Contained**: Each feature can be understood in isolation + deleted without affecting other tools
3. **Discoverable**: The root level of `/tools` shows all available tools
4. **No Nesting**: Features are all at the root level, not in category subfolders

## Adding a New Tool

1. Duplicate and rename the `@new` template directory at the root level of `/tools`
1. Update or delete each example file
1. Reference `{tool}/install.bash` in `features/setup/setup.bash` - _automate?_
1. Reference `{tool}/update.bash` in `features/update/update.bash` - _automate?_

## Deprecating a Tool

1. Run `{tool}/uninstall.bash`
2. Move folder to `tools/@archive`
