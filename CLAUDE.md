# CLAUDE.md

This file provides Claude-specific guidance when working with this dotfiles repository.

For general project information, installation instructions, and usage details, see the [README](./README.md).

## Claude-Specific Notes

### File Structure Reference
See README.md for the complete overview. Key points for Claude:

**Current Active Structure:**
- Installation scripts are in `bin/install/` (individual .zsh files)
- Update scripts are in `bin/update/`
- Main setup script is `setup.zsh` in project root
- Configuration files are in `config/` directories

**Future Bash Structure (In Development - Not Yet Active):**
- Core functionality being built in `core/` (bash modules for shared logic)
- Feature-specific code being built in `features/` (individual feature directories with bash scripts)
- Future main setup script will be `setup.bash`
- **Note**: These bash files are not yet functional or ready for use

### Available Commands and Scripts

For accurate command information, refer to README.md. The actual files in this repository are:

**Current Active Scripts:**

**Installation scripts** (`bin/install/`):
- `ssh.zsh`, `github.zsh`, `homebrew.zsh`, `zsh.zsh`, `rust.zsh`, `uv.zsh`, `node.zsh`, `tmux.zsh`, `neovim.zsh`, `yazi.zsh`, `content.zsh`, `settings.zsh`

**Update scripts** (`bin/update/`):
- `homebrew.zsh`, `npm.zsh`, `neovim.zsh`, `tmux.zsh`, `rust.zsh`, `symlinks.zsh`, `ssh.zsh`, `yazi.zsh`, `gcloud.zsh`, `macos.zsh`, `mode.zsh`

**Future Bash Structure (In Development - Do Not Use):**

**Core modules** (`core/`) - Under construction:
- `detection/` - Machine and macOS detection logic
- `dry-run/` - Dry run utilities
- `errors/` - Error handling
- `permissions/` - Permission utilities
- `prerequisites/` - Installation prerequisites validation
- `symlinks/` - Symlink management
- `testing/` - Testing utilities and test suite

**Feature modules** (`features/`) - Under construction:
- Each feature directory contains `install.bash`, `update.bash`, `utils.bash`, and `README.md`
- Features being developed: `content`, `git`, `github`, `homebrew`, `macos`, `neovim`, `node`, `rust`, `settings`, `ssh`, `tmux`, `uv`, `yazi`, `zsh`

### Symlink Management

**Important for Git commits**: Files in `home/.claude/` are symlinked to `~/.claude/`. To commit changes to global Claude settings (like `~/.claude/CLAUDE.md`), commit the dotfiles copy at `home/.claude/CLAUDE.md` instead of trying to commit outside the repository.

The symlink creation logic is in `bin/update/symlinks.zsh`. (Note: `core/symlinks/` is under development and not yet functional).

### Machine Detection

The setup detects machine types based on hostname patterns in `setup.zsh`:
- Contains "Air" → Personal laptop configuration  
- Contains "Mini" → Home server configuration
- All others → Work machine configuration

Work-specific files are conditionally loaded when detected:
- `config/zsh/work.zsh` - Work-specific aliases and functions
- `config/git/work.gitconfig` - Work Git configuration

Machine detection logic is in `bin/lib/machine-detection.zsh` and sets these variables:
- `MACHINE` - "air", "mini", or "work"
- `IS_AIR`, `IS_MINI`, `IS_WORK` - boolean variables for conditional loading

### Claude Development Workflow

When making changes to this repository:

1. **Always check README.md first** for current, accurate information
2. **Verify file existence** before referencing scripts or commands
3. **Use actual file paths** from the repository structure
4. **Test changes** using the test suite: `./test/run-tests.zsh`
5. **Update README.md** for any user-facing changes
6. **Keep this CLAUDE.md focused** on Claude-specific guidance only

### File Path Verification

**CRITICAL: Always verify file paths exist before referencing them in documentation:**

1. **Use `ls` commands** to check actual file names before referencing them
2. **Don't assume numbered prefixes** (e.g., `1-ssh.zsh`) - actual files are named `ssh.zsh`, `homebrew.zsh`, etc.
3. **Check correct directories** - symlinks script is in `bin/update/`, not `bin/install/`
4. **Verify before updating task docs** - use `ls bin/install/` and `ls bin/update/` to confirm file names
5. **Common mistake**: Referencing `bin/install/1-ssh.zsh` when actual file is `bin/install/ssh.zsh`

**Before documenting any file path, run:**
```bash
ls bin/install/  # Check installation scripts
ls bin/update/   # Check update scripts  
```

### Testing and Verification

- See `test/README.md` for detailed testing documentation
- Run `symlinks` to recreate all symlinks
- Test individual install scripts by sourcing them
- Use `setup.zsh --dry-run` to preview changes

### Shellcheck Standards

**IMPORTANT: Always use `.shellcheckrc` for configuration, never inline comments**

When working with bash scripts in this repository:

1. **Fix issues, don't ignore them** - If shellcheck reports an issue, fix the code rather than adding ignore directives
2. **Use `.shellcheckrc` for project-wide settings** - All shellcheck configuration should be centralized in the `.shellcheckrc` file
3. **Never use inline shellcheck directives** - Don't add comments like `# shellcheck disable=SC2155`
4. **Common fixes**:
   - SC2155: Separate variable declaration from assignment when using command substitution
   - Example: Change `local var="$(command)"` to `local var` then `var="$(command)"`

- **Always add shellcheck directives to `.shellcheckrc`, not as individual comments**

All bash scripts must pass shellcheck with zero warnings before merging.

### Project-Specific Git Ignore
Use the `.gitignore` file and not the `config/git/ignore` file when adding project-specific ignore rules.
