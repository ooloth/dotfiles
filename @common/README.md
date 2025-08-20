# Common Utilities

This directory contains cross-cutting utilities used by multiple features. These are infrastructure-level concerns that don't belong to any single feature.

## Architecture

```
@common/
├── {helper}/
│   ├── utils.bash   # Shared utilities
│   ├── tests/       # Feature-specific tests
│   └── README.md    # Helper documentation (optional)
```

```

```

## Utilities

### Detection

- Machine type detection (personal, work, server)
- OS and version detection
- Environment variable validation

### Prerequisites

- Command availability checks
- Network connectivity validation
- System requirement verification

### Dry Run

- Safe mode execution
- Command preview without execution
- Change simulation

### Errors

- Error capture and logging
- Retry mechanisms with backoff
- User-friendly error messaging

## Usage

Common utilities are sourced by features as needed:

```bash
# In a feature's install.bash
source "$DOTFILES/@common/detection/machine.bash"
source "$DOTFILES/@common/errors/handling.bash"
```

## Standards

All common utilities must:

- Pass shellcheck with zero warnings
- Have comprehensive bats tests
- Work independently (no cross-dependencies)
- Be well-documented with examples
