---
name: add-tool
description: Add a new tool to the dotfiles repository. Use when asked to add a new CLI tool, application, or package as a managed dotfiles tool.
---

## Context

- Existing tools: !`ls "${DOTFILES}/tools" | grep -v ^@`
- Template: `tools/@new/` — reference for file structure and patterns

## Your task

Add a new tool to this dotfiles repository. Follow these steps:

### 1. Research the tool

Before writing any files:

- **How is it installed?** Check its README/docs for the recommended installer. Common options: `brew install`, `npm install -g`, `bun install -g`, `uv tool install`, `cargo install`, or a custom install script.
- **What does `{command} --version` output?** Run it (or check the docs) to know the exact format — you'll need this to write `parse_version`.
- **Are there zsh completions?** Check the docs or the brew caveats after install. If completions require explicit shell setup (e.g. `eval "$(tool completion zsh)"`), note it — you'll need `shell.zsh`.
- **Does it have dotfiles config to manage?** If it writes config to `~/.config/{tool}/` or similar, you'll need `symlinks/`.

### 2. Classify the tool

**Simple tool** (no dotfiles config to symlink): needs only the 4 core files.
Examples: `eza`, `sd`, `logcli`

**Tool with config** (has config files to symlink): also needs `symlinks/link.bash`, `symlinks/unlink.bash`, and a `config/` directory.
Examples: `claude`, `neovim`, `git`

### 3. Create `tools/{tool}/utils.bash`

```bash
#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="{tool}"
export TOOL_UPPER="{Tool}"
export TOOL_COMMAND="{tool}"
export TOOL_PACKAGE="{package-name}"
export TOOL_EMOJI="🔧"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"  # omit if no config

parse_version() {
  local raw_version="${1}"
  # Adapt to match the actual output of the version command (arg 6 in install/update):
  printf "${raw_version}"
}
```

Key variables:
- `TOOL_LOWER`: lowercase name used in paths and log messages
- `TOOL_UPPER`: display name (often same as `TOOL_LOWER`, but e.g. `"Claude Code"`)
- `TOOL_COMMAND`: the binary name (`which` resolves this)
- `TOOL_PACKAGE`: the package name passed to the installer
- `TOOL_EMOJI`: used in log output
- `TOOL_CONFIG_DIR`: only needed for tools with config; omit the export if unused

**`parse_version` by installer** — receives the raw output of the version command (arg 6) and must return a clean semver string:

| Installer | Version command (arg 6) | Typical raw output | `parse_version` logic |
|---|---|---|---|
| `brew` | `brew list --version {pkg}` | `sd 1.0.0` | strip `"sd "` prefix |
| `npm` / `bun` | `{command} --version` | `1.10.2` | print as-is |
| `npm` (some) | `{command} --version` | `1.0.0 (Claude Code)` | strip suffix |
| `uv tool` | `{pkg} --version` | `ty, version 0.0.1` | strip `"ty, version "` prefix |
| `cargo` | `{command} --version` | `sd 1.0.0` | strip `"sd "` prefix |

### 4. Create `tools/{tool}/install.bash`

Structure is always the same — only the install command (arg 5) and version command (arg 6) change by installer:

**brew:**
```bash
#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/{tool}/utils.bash" # source last to avoid env var overrides

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew install --formula ${TOOL_PACKAGE}" \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version"
```

**npm:**
```bash
  "npm install --global ${TOOL_PACKAGE}@latest" \
  "${TOOL_COMMAND} --version" \
```

**bun:**
```bash
  "bun install --global ${TOOL_PACKAGE}" \
  "${TOOL_COMMAND} --version" \
```

**uv:**
```bash
  "uv tool install ${TOOL_PACKAGE}" \
  "${TOOL_PACKAGE} --version" \
```

**cargo:**
```bash
  "cargo install ${TOOL_PACKAGE}" \
  "${TOOL_COMMAND} --version" \
```

For **tools with config**, add the symlink script path as an 8th argument:

```bash
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"
```

### 5. Create `tools/{tool}/update.bash`

Same pattern — update command varies by installer, 8th arg is always the install script fallback:

**brew:**
```bash
#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/{tool}/utils.bash" # source last to avoid env var overrides

update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew upgrade --formula ${TOOL_PACKAGE}" \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash"
```

Update commands by installer: `brew upgrade --formula {pkg}` / `npm install --global {pkg}@latest` / `bun install --global {pkg}` / `uv tool upgrade {pkg}` / `cargo install {pkg}`

For **tools with config**, add the symlink script path as a 9th argument:

```bash
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"
```

### 6. Create `tools/{tool}/uninstall.bash`

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/uninstall/utils.bash"
source "${DOTFILES}/tools/{tool}/utils.bash" # source last to avoid env var overrides

uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew uninstall --formula ${TOOL_PACKAGE}"
```

Uninstall commands: `brew uninstall --formula {pkg}` / `npm uninstall --global {pkg}` / `bun uninstall --global {pkg}` / `uv tool uninstall {pkg}` / `cargo uninstall {pkg}`

### 7. Create `tools/{tool}/shell.zsh` (only if needed)

Only create this file if the tool requires explicit shell setup: environment variables, aliases, or completions not auto-installed by the package manager.

Brew auto-installs completions to `/opt/homebrew/share/zsh/site-functions` — no `shell.zsh` needed for those. Only add completion setup if the tool's docs require something like `eval "$(tool completion zsh)"` or `source <(tool completions zsh)`.

```zsh
########################
# ENVIRONMENT VARIABLES #
########################

# export SOME_VAR="value"

###########
# ALIASES #
###########

# alias x="tool --flag"

###############
# COMPLETIONS #
###############

# eval "$(tool completion zsh)"
```

### 8. For tools with config: create `symlinks/`

`tools/{tool}/symlinks/link.bash`:

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/{tool}/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/{tool}/config/settings.json" "${TOOL_CONFIG_DIR}/settings.json"
```

`tools/{tool}/symlinks/unlink.bash`:

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/{tool}/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

trash "${TOOL_CONFIG_DIR}"
```

### 9. Verify

```bash
shellcheck tools/{tool}/*.bash
```

Run the install script to confirm it works end-to-end:

```bash
DOTFILES="$HOME/Repos/ooloth/dotfiles" bash tools/{tool}/install.bash
```

## Notes

- **Auto-discovery**: `features/install/tools.bash` and `features/update/tools.bash` use `find` to discover all `install.bash` / `update.bash` files under `tools/` automatically. No manual registration is needed.
- **Shell manifest**: `shell.zsh` is sourced automatically in every new shell via the generated manifest at `$DOTFILES/.cache/shell-files-manifest.zsh`. Regenerate it with the `symlinks` alias after adding a new tool.
