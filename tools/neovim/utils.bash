#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="neovim"
export TOOL_UPPER="Neovim"
export TOOL_COMMAND="nvim"
export TOOL_PACKAGE="neovim"
export TOOL_EMOJI="🦸"
export TOOL_CONFIG_DIR="${HOME}/.config/nvim"

export TOOL_HOMEBREW_DEPENDENCIES=(
  basedpyright               # python: https://docs.basedpyright.com/latest/installation/command-line-and-language-server/
  hashicorp/tap/terraform    # terraform: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
  hashicorp/tap/terraform-ls # terraform: https://github.com/hashicorp/terraform-ls/blob/main/docs/installation.md
  lua-language-server        # lua: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#lua_ls
  marksman                   # markdown: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#marksman
  ruff                       # python: ...
  shellcheck                 # bash: ...
  shfmt                      # bash: ...
  stylua                     # lua: https://github.com/JohnnyMorganz/StyLua?tab=readme-ov-file#homebrew
  taplo                      # toml: https://taplo.tamasfe.dev/cli/installation/homebrew.html
  tflint                     # terraform: https://github.com/terraform-linters/tflint
  tidy-html5                 # html/xml: ...
)

export TOOL_NPM_DEPENDENCIES=(
  @astrojs/language-server          # astro: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#astro
  @mdx-js/language-service          # mdx: https://github.com/mdx-js/mdx-analyzer/tree/main/packages/typescript-plugin
  @olrtg/emmet-language-server      # emmet: ...
  @tailwindcss/language-server      # tailwind: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#tailwindcss
  bash-language-server              # bash: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#bashls
  css-variables-language-server     # css: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#css_variables
  cssmodules-language-server        # css modules: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#cssmodules_ls
  dockerfile-language-server-nodejs # dockerfile: ...
  neovim                            # neovim: ...
  prettier                          # many languages: ...
  pug-linter                        # pug: ...
  svelte-language-server            # svelte: ...
  tree-sitter-cli                   # tree-sitter: ...
  typescript                        # ts: ...
  typescript-language-server        # ts: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#ts_ls
  vls                               # vue: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vuels
  vscode-langservers-extracted      # astro/eslint/json: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
  yaml-language-server              # yaml: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#yamlls
)

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
