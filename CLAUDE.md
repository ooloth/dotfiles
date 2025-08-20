# CLAUDE.md

This file provides Claude-specific guidance when working with this dotfiles repository.

For general project information, installation instructions, and usage details, see the [README](./README.md).

## Folder Structure

See README.md for the complete overview. Key points for Claude:

**Current Active Structure:**

- Installation scripts are in `bin/install/` (individual .zsh files)
- Update scripts are in `bin/update/`
- Main setup script is `setup.zsh` in project root
- Configuration files are in `config/` directories

**Future Bash Structure (In Development - Not Yet Active):**

- Common functionality being built in `@common/` (bash modules for shared logic)
- Feature-specific code being built in `features/` (individual feature directories with bash scripts)
- Future main setup script will be `setup.bash`
- **Note**: These bash files are not yet functional or ready for use

**Future Bash Common Modules** (`common/`) - Under construction:

- `detection/` - Machine and macOS detection logic
- `dry-run/` - Dry run utilities
- `errors/` - Error handling
- `permissions/` - Permission utilities
- `prerequisites/` - Installation prerequisites validation
- `symlinks/` - Symlink management
- `testing/` - Testing utilities and test suite

**Future Bash Feature Modules** (`features/`) - Under construction:

- Each feature directory contains `install.bash`, `update.bash`, `utils.bash`, and `README.md`
- Features being developed: `content`, `git`, `github`, `homebrew`, `macos`, `neovim`, `node`, `rust`, `settings`, `ssh`, `tmux`, `uv`, `yazi`, `zsh`

### Symlink Management

**Important for Git commits**: Files in `home/.claude/` are symlinked to `~/.claude/`. To commit changes to global Claude settings (like `~/.claude/CLAUDE.md`), commit the dotfiles copy at `home/.claude/CLAUDE.md` instead of trying to commit outside the repository.

The symlink creation logic is in `bin/update/symlinks.zsh`. (Note: `@common/symlinks/` is under development and not yet functional).

### Claude Development Workflow

When making changes to this repository:

1. **Verify file existence** before referencing scripts or commands
1. **Use actual file paths** from the repository structure
1. **Update all relevant README.md files** after making any user-facing changes
1. **Update all relevant project-level CLAUDE.md files** after clarifying any Claude-specific workflows

### Testing and Verification

- All bash scripts must pass `shellcheck` and `bats` checks in order to pass CI
- **Use `.shellcheckrc` for project-wide settings** - centralized configuration in the `.shellcheckrc` file instead of using disable comments
- See `test/README.md` for detailed testing documentation
- Run `symlinks` to recreate all symlinks
- Test individual scripts by sourcing them
