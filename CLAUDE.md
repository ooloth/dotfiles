# CLAUDE.md

This file provides Claude-specific guidance when working with this dotfiles repository.

For general project information, installation instructions, and usage details, see the [README](./README.md).

## Folder Structure

See README.md for the complete overview. Key points for Claude:

**Current Active Structure:**

- Installation scripts are in `features/install/zsh/` (individual .zsh files)
- Update scripts are in `features/update/zsh/`
- Main setup script is `features/setup/setup.zsh`
- Configuration files are in `tools/{tool}/config/` directories

**Folder Structure**

- Common functionality being built in `features/common/` (bash modules for shared logic)
- Tool-specific logic is in `tools/{tool}/` folders
- Feature-specific code (leveraging one or more tools) is in `features/{feature}/` folders
- Future main setup script will be `features/setup/setup.bash`
- Future main update script will be `features/update/bash/tools.bash`
- **Note**: These bash files are not yet functional or ready for use

**Self-Contained Feature Modules** (`features/common/`) - Under construction:

- `detection/` - Machine and macOS detection logic
- `dry-run/` - Dry run utilities
- `errors/` - Error handling
- `permissions/` - Permission utilities
- `prerequisites/` - Installation prerequisites validation
- `symlinks/` - Symlink management
- `testing/` - Testing utilities and test suite

**Self-Contained Tool Modules** (`tools/{tool}/`)

- See `tools/@new` for an example of the files in each folder
- See `tools/README.md` for an explanation of the feature folder approach
- For brew formulae without config, see `tools/eza/` or `tools/logcli/` as examples

### Symlink Management

**Important for Git commits**: Files in `tools/claude/config/` are symlinked to `~/.claude/`. To commit changes to global Claude settings (like `~/.claude/CLAUDE.md`), commit the dotfiles copy at `tools/claude/config/CLAUDE.md` instead of trying to commit outside the repository.

The symlink creation logic is in `features/update/symlinks.zsh`. (Note: `tools/bash/wip/symlinks/*.bash` are under development and not yet functional).

### Claude Development Workflow

When making changes to this repository:

1. **Verify file existence** before referencing scripts or commands
1. **Use actual file paths** from the repository structure
1. **Update all relevant README.md files** after making any user-facing changes
1. **Update all relevant project-level CLAUDE.md files** after clarifying any Claude-specific workflows

### Testing and Verification

- All bash scripts must pass `shellcheck` and `bats` checks in order to pass CI
- **Use `.shellcheckrc` for project-wide settings** - centralized configuration in the `.shellcheckrc` file instead of using disable comments
- Run `symlinks` alias to recreate all symlinks
- Test individual scripts by sourcing them
