# Repository Guidelines

## Project Structure & Module Organization
- `features/` houses workflow scripts (setup, install, update, run, test, etc.). Active install/update logic lives under `features/install/zsh/` and `features/update/zsh/`.
- `tools/{tool}/` is the unit of configuration. Expect `config/` for dotfiles, `shell/` for aliases/variables, and `symlinks/` for link/unlink scripts (see `tools/README.md`).
- Work-in-progress or experimental Bash rewrites may appear under `features/**/wip/` or `tools/**/wip/`.

## Build, Test, and Development Commands
- `features/setup/setup.zsh` bootstraps a new machine and runs the full install flow.
- `u` updates everything; `u "homebrew"` updates a single tool (see README).
- `symlinks` refreshes dotfile symlinks after config changes.
- There is no single test runner command; CI expects `shellcheck` and `bats` checks. Use `shellcheck -x path/to/script.zsh` and `bats path/to/test.bats` as needed.

## Coding Style & Naming Conventions
- Shell scripts are primarily `.zsh` for active workflows and `.bash` for shared tooling; keep scripts executable with a shebang.
- Use 2-space indentation in shell scripts (match existing files like `features/setup/setup.zsh`).
- Keep lint settings centralized in `.shellcheckrc`; avoid inline disables when possible.
- Use existing formatter configs when relevant: `.prettierrc`, `.stylua.toml`, `.taplo.toml`.

## Testing Guidelines
- BATS tests live under `features/**/wip/tests/` and use helpers in `tools/bats/utils.bash`.
- Name tests descriptively and keep them close to the feature area being validated.

## Commit & Pull Request Guidelines
- Commit messages follow a short `scope: description` style (e.g., `mise: remove broken imports`, `start: add ops repo case`).

## Configuration & Symlinks
- Tool configs are symlinked into `~` from `tools/{tool}/config/`; update the repo copies, not the home-directory targets.
- Symlink orchestration lives in `features/update/symlinks.zsh` and tool-level `symlinks/` scripts.
