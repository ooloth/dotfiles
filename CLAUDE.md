# CLAUDE.md

This file provides Claude-specific guidance when working with this dotfiles repository.

For general project information, installation instructions, and usage details, see [README.md](README.md).

## Claude-Specific Notes

### File Structure Reference
See README.md for the complete overview. Key points for Claude:

- Installation scripts are in `bin/install/` (individual .zsh files)
- Update scripts are in `bin/update/` 
- **Utility libraries** are in `bin/lib/` (machine detection, prerequisites, dry-run, error handling)
- Main setup script is `setup.zsh` in project root
- Configuration files are in `config/` directories
- Test suite is in `test/` directory with comprehensive testing framework

### Available Commands and Scripts

For accurate command information, refer to README.md. The actual files in this repository are:

**Installation scripts** (`bin/install/`):
- `ssh.zsh`, `github.zsh`, `homebrew.zsh`, `zsh.zsh`, `rust.zsh`, `uv.zsh`, `node.zsh`, `tmux.zsh`, `neovim.zsh`, `yazi.zsh`, `content.zsh`, `settings.zsh`

**Update scripts** (`bin/update/`):
- `homebrew.zsh`, `npm.zsh`, `neovim.zsh`, `tmux.zsh`, `rust.zsh`, `symlinks.zsh`, `ssh.zsh`, `yazi.zsh`, `gcloud.zsh`, `macos.zsh`, `mode.zsh`

**Utility libraries** (`bin/lib/`):
- `machine-detection.zsh` - Dynamic hostname-based machine type detection
- `prerequisite-validation.zsh` - System prerequisites validation (CLI tools, network, macOS version)
- `dry-run-utils.zsh` - Dry-run mode functionality for safe preview
- `error-handling.zsh` - Error capture, retry mechanisms, and user-friendly messaging

### Symlink Management

**Important for Git commits**: Files in `home/.claude/` are symlinked to `~/.claude/`. To commit changes to global Claude settings (like `~/.claude/CLAUDE.md`), commit the dotfiles copy at `home/.claude/CLAUDE.md` instead of trying to commit outside the repository.

The symlink creation logic is in `bin/update/symlinks.zsh`.

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
ls bin/lib/      # Check utility libraries
ls test/         # Check test structure
```

### Testing and Verification

- Comprehensive test suite exists in `test/` directory
- Run all tests: `./test/run-tests.zsh`
- Run specific tests: `./test/run-tests.zsh <pattern>`
- Test framework includes mocking, assertions, and isolated environments
- See `test/README.md` for detailed testing documentation
- Run `symlinks` to recreate all symlinks
- Test individual install scripts by sourcing them
- Use `setup.zsh --dry-run` to preview changes

#### Test Framework Structure

- `test/setup/` - Tests for setup process (machine detection, prerequisites, dry-run, error handling)
- `test/install/` - Tests for installation scripts (with specialized testing infrastructure)
- `test/install/lib/` - Installation-specific test utilities and mocking framework
- `test/lib/` - Core testing utilities shared across all tests

#### Installation Script Testing

- **Specialized framework** in `test/install/lib/` for testing installation scripts safely
- **Environment isolation** - tests run in mock directories without affecting host system
- **Comprehensive mocking** - all external dependencies (brew, git, ssh, curl, etc.) are mocked
- **Behavioral testing focus** - tests verify installation outcomes, not implementation details
- See `test/install/README.md` for complete usage examples and available utilities

#### Test Coverage Verification Commands

Verify all expected test files are running:

```bash
# Count actual test files (exclude lib files and test runner)
find test/ -name "test-*.zsh" -perm +111 | grep -v "lib/" | grep -v "run-tests.zsh" | wc -l

# Compare with test runner output: "Found X test file(s) to run"
./test/run-tests.zsh

# List all test directories
find test/ -type d -name "*test*" -o -name "test*"

# List actual test files being counted
find test/ -name "test-*.zsh" -perm +111 | grep -v "lib/" | grep -v "run-tests.zsh"
```

The numbers should match to ensure no test files are being missed.

### Shellcheck Standards

**CRITICAL REQUIREMENT: NEVER use inline shellcheck directives - Always use `.shellcheckrc`**

**ABSOLUTE POLICY**: This repository has a strict policy against inline shellcheck comments. Any use of `# shellcheck disable=` or similar inline directives is FORBIDDEN and must be removed immediately.

When working with bash scripts in this repository:

1. **Fix issues, don't ignore them** - If shellcheck reports an issue, fix the code rather than adding ignore directives
2. **MANDATORY: Use `.shellcheckrc` for ALL configuration** - All shellcheck configuration must be centralized in the `.shellcheckrc` file
3. **FORBIDDEN: Never use inline shellcheck directives** - Comments like `# shellcheck disable=SC2155` are strictly prohibited
4. **If you must disable a check**: Add it to `.shellcheckrc` with proper documentation explaining why
5. **Common fixes**:
   - SC2155: Separate variable declaration from assignment when using command substitution
   - Example: Change `local var="$(command)"` to `local var` then `var="$(command)"`

**ENFORCEMENT**: All bash scripts must pass shellcheck with zero warnings before merging. Any PR containing inline shellcheck directives will be rejected.

### Project-Specific Git Ignore
Use the `.gitignore` file and not the `config/git/ignore` file when adding project-specific ignore rules.