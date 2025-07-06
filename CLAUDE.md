# CLAUDE.md

This file provides Claude-specific guidance when working with this dotfiles repository.

For general project information, installation instructions, and usage details, see [README.md](README.md).

## Claude-Specific Notes

### File Structure Reference
See README.md for the complete overview. Key points for Claude:

- Installation scripts are in `bin/install/` (individual .zsh files)
- Update scripts are in `bin/update/` 
- Main setup script is `setup.zsh` in project root
- Configuration files are in `config/` directories
- Test suite is in `test/` directory with comprehensive testing framework

### Available Commands and Scripts

For accurate command information, refer to README.md. The actual files in this repository are:

**Installation scripts** (`bin/install/`):
- `ssh.zsh`, `github.zsh`, `homebrew.zsh`, `zsh.zsh`, `rust.zsh`, `uv.zsh`, `node.zsh`, `tmux.zsh`, `neovim.zsh`, `yazi.zsh`, `content.zsh`, `settings.zsh`

**Update scripts** (`bin/update/`):
- `homebrew.zsh`, `npm.zsh`, `neovim.zsh`, `tmux.zsh`, `rust.zsh`, `symlinks.zsh`, `ssh.zsh`, `yazi.zsh`, `gcloud.zsh`, `macos.zsh`, `mode.zsh`

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

### Claude Development Workflow

When making changes to this repository:

1. **Always check README.md first** for current, accurate information
2. **Verify file existence** before referencing scripts or commands
3. **Use actual file paths** from the repository structure
4. **Test changes** using the test suite: `./test/run-tests.zsh`
5. **Update README.md** for any user-facing changes
6. **Keep this CLAUDE.md focused** on Claude-specific guidance only

### Testing and Verification

- Comprehensive test suite exists in `test/` directory
- Run all tests: `./test/run-tests.zsh`
- Run specific tests: `./test/run-tests.zsh <pattern>`
- Test framework includes mocking, assertions, and isolated environments
- See `test/README.md` for detailed testing documentation
- Run `symlinks` to recreate all symlinks
- Test individual install scripts by sourcing them
- Use `setup.zsh --dry-run` to preview changes

### Project-Specific Git Ignore
Use the `.gitignore` file and not the `config/git/ignore` file when adding project-specific ignore rules.