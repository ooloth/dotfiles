# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Commands

### Installation
```bash
# Full installation on a new machine
./setup.zsh

# Individual installation scripts
./bin/install/1-ssh.zsh              # Generate SSH keys and authenticate with GitHub
./bin/install/2-homebrew.zsh         # Install Homebrew and all packages
./bin/install/3-programming.zsh      # Install programming languages (Node.js, Rust, Python)
./bin/install/4-shell.zsh            # Configure Zsh as default shell
./bin/install/5-app-deps.zsh         # Install app dependencies (tmux plugins, Neovim plugins, etc.)
./bin/install/6-symlink.zsh          # Create symlinks for all dotfiles
./bin/install/7-macos.zsh            # Configure macOS system preferences
```

### Updates
```bash
# Update all components
update                      # Alias that runs: update-dotfiles && update-homebrew && update-npm

# Individual update commands
update-dotfiles            # Pull latest changes from git
update-homebrew            # Update Homebrew packages
update-npm                 # Update global npm packages
update-nvim-plugins        # Update Neovim plugins
update-tmux-plugins        # Update tmux plugins
update-symlinks            # Recreate all symlinks
```

### Testing and Linting
```bash
# Test symlinks
./bin/generate/test-symlinks.zsh    # Lists all symlinks that would be created

# No formal test suite or linting for shell scripts
# Manually test changes by running relevant scripts
```

## Architecture Overview

### Directory Structure
```
dotfiles/
├── bin/                   # Installation and maintenance scripts
│   ├── generate/          # Utility scripts (test-symlinks.zsh)
│   ├── install/           # Numbered installation scripts (1-7)
│   ├── reinstall/         # Complete reinstallation scripts
│   ├── uninstall/         # Cleanup scripts
│   └── update/            # Update scripts for various components
├── config/                # Application configurations
│   ├── git/               # Git configs (personal.gitconfig, work.gitconfig)
│   ├── nvim/              # Neovim configuration
│   ├── tmux/              # tmux configuration
│   ├── vscode/            # VS Code settings and extensions
│   ├── yazi/              # File manager configuration
│   └── zsh/               # Shell configuration
├── kinesis-advantage-2/   # Keyboard firmware
├── library/               # macOS Library files (VS Code)
├── macos/                 # Brewfile and system defaults
└── setup.zsh             # Main installation orchestrator
```

### Main Installation Flow (setup.zsh)
1. Detects machine type (Air, Mini, or Work) via hostname
2. Sets environment variables (DOTFILES, MACHINE)
3. Executes installation scripts in order (1-7)
4. Each script is idempotent and can be run independently

### Update Scripts Architecture
- `update-dotfiles`: Git pull from main branch
- `update-homebrew`: Updates formulae, upgrades packages, runs cleanup and doctor
- `update-npm`: Updates npm itself and global packages (pm2, pnpm, wrangler)
- `update-nvim-plugins`: Runs Lazy.nvim sync
- `update-rust`: Updates rustup and rust-analyzer
- `update-symlinks`: Recreates all symlinks using bin/install/6-symlink.zsh
- `update-tmux-plugins`: Updates TPM plugins

## Machine-Specific Configuration

The setup detects three machine types:
- **Air**: Personal MacBook Air (additional languages: Mojo, Deno, Gleam)
- **Mini**: Mac Mini home server (backup tools: Backblaze, Carbon Copy Cloner)
- **Work**: Work computers (enterprise tools: Codefresh, Vault, Kafka, Redis)

Machine detection in `config/zsh/.zshrc`:
```bash
case "$HOSTNAME" in
    *Air*)      MACHINE="air" ;;
    *Mini*)     MACHINE="mini" ;;
    *)          MACHINE="work" ;;
esac
```

Work-specific files are conditionally loaded:
- `config/zsh/work.zsh` - Work-specific aliases and functions
- `config/git/work.gitconfig` - Work Git configuration

## Symlink Strategy

The `maybe_symlink()` function in `bin/install/6-symlink.zsh`:
- Creates symlinks only if they don't already exist
- Preserves existing symlinks (doesn't recreate)
- Creates parent directories as needed
- All symlinks point from system locations to files in the dotfiles repo

Example symlinks:
- `~/.config/nvim` → `$DOTFILES/config/nvim`
- `~/.gitconfig` → `$DOTFILES/config/git/.gitconfig`
- `~/.zshrc` → `$DOTFILES/config/zsh/.zshrc`

**Important for Git commits**: Files in `home/.claude/` are symlinked to `~/.claude/`. To commit changes to global Claude settings (like `~/.claude/CLAUDE.md`), commit the dotfiles copy at `home/.claude/CLAUDE.md` instead of trying to commit outside the repository.

## Dependencies

### Core Tools (All Machines)
- Shell: zsh, bash, starship
- Terminal: kitty, alacritty, tmux
- Editors: neovim, vscode
- Git: git, gh, lazygit, delta
- File Management: yazi, eza, fd, ripgrep, fzf
- Container: docker, lazydocker
- Languages: fnm (Node.js), rustup, go

### Work-Specific Tools
- Python: uv (replaces homebrew python)
- Kubernetes: kubectl, k9s, kdash, helm, kustomize
- Infrastructure: vault, terraform, codefresh
- Databases: redis, kafka

### Personal Machine Tools (Air/Mini)
- Languages: deno, gleam, mojo
- Media: ffmpeg, yt-dlp
- Additional CLI tools

## Key Aliases and Functions

### Navigation
- `cc` - cd to ~/Code
- `c <dir>` - cd to ~/Code/<dir>
- `cf` - cd to dotfiles
- `cw` - cd to work code directory

### Updates
- `update` - Update dotfiles, homebrew, and npm
- `update-all` - Update everything including plugins

### Development
- `g` - git
- `lg` - lazygit
- `k` - kubectl
- `d` - docker
- `ld` - lazydocker
- `v` - nvim
- `y` - yazi

### Container Management
- `dcu` - docker compose up
- `dcd` - docker compose down
- `dcr` - docker compose restart
- `dps` - docker ps with formatting
- `dpsa` - docker ps -a with formatting

## Work-Specific Features

When `MACHINE="work"`:
1. Loads `config/zsh/work.zsh` with work-specific aliases
2. Uses `config/git/work.gitconfig` for Git configuration
3. Installs additional Homebrew packages (see macos/Brewfile)
4. Sets up Python via `uv` instead of Homebrew Python
5. Configures work-specific tools (Vault, Codefresh, etc.)

## Important Notes

### Symlink Management
- Always use `maybe_symlink()` to avoid overwriting existing symlinks
- Run `update-symlinks` after adding new files to be symlinked
- Test with `./bin/generate/test-symlinks.zsh` before running

### Machine Detection
- Based on hostname pattern matching
- Export `MACHINE` variable to override detection
- Work is the default for unrecognized hostnames

### Update Order
1. Always update dotfiles first (git pull)
2. Then update package managers (homebrew, npm)
3. Finally update plugins (nvim, tmux)

### Path Management
- `DOTFILES` is set to the repository location
- All scripts use `$DOTFILES` for portable paths
- Work machines have additional PATH entries

### Git Configuration
- Personal: Uses config/git/personal.gitconfig
- Work: Additionally includes config/git/work.gitconfig
- Both use delta for enhanced diffs

## Common Tasks

### Adding a New Application Configuration
1. Create directory in `config/<app-name>/`
2. Add configuration files
3. Add symlink in `bin/install/6-symlink.zsh`
4. Run `update-symlinks` to create the symlink

### Adding Homebrew Packages
1. Edit `macos/Brewfile`
2. Add to appropriate section (formulae, casks, mas)
3. Run `update-homebrew` to install

### Adding Machine-Specific Configuration
1. Use conditional in relevant config file:
   ```bash
   if [[ "$MACHINE" == "work" ]]; then
     # Work-specific config
   fi
   ```
2. Or create separate files loaded conditionally

### Debugging
- Check `$MACHINE` and `$DOTFILES` variables
- Run individual install scripts to isolate issues
- Use `test-symlinks.zsh` to verify symlink targets
- Check script permissions (should be executable)

## Project-Specific Git Ignore
- Use the `.gitignore` file and not the `config/git/ignore` file when adding project-specific ignore rules