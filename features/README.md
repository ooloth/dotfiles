# Features Directory

This directory contains self-contained feature modules for the dotfiles bash infrastructure. Each tool/feature gets its own folder with all related files grouped together.

## Architecture

```
features/
├── {tool}/
│   ├── install.bash   # Installation logic
│   ├── update.bash    # Update logic (if applicable)
│   ├── utils.bash     # Shared utilities
│   ├── config/        # Tool-specific configs to symlink
│   ├── tests/         # Feature-specific tests
│   └── README.md      # Feature documentation (optional)
```

## Key Principles

1. **Feature Cohesion**: Everything related to a tool lives in one folder
2. **Self-Contained**: Each feature can be understood in isolation
3. **Discoverable**: `ls features/` shows all available tools
4. **Testable**: Tests live with the code they test
5. **No Nesting**: Features are directly under `/features`, not in category subfolders

## Adding a New Feature

1. Create a new directory: `features/{tool}/`
2. Add the standard files (install.bash, utils.bash, etc.)
3. Move or create tests in `features/{tool}/tests/`
4. Update `setup.bash` will auto-discover your feature

## Migration Status

This is part of the bash infrastructure migration. During the transition:
- New bash features go here
- Existing zsh scripts remain in their current locations
- Both systems work in parallel

See GitHub issue #43 for the complete migration plan.