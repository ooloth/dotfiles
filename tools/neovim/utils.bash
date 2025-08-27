#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="neovim"
export TOOL_UPPER="Neovim"
export TOOL_COMMAND="nvim"
export TOOL_PACKAGE="neovim"
export TOOL_EMOJI="🦸"
export TOOL_CONFIG_DIR="${HOME}/.config/nvim"

# TODO: brew tap hashicorp/tap
export TOOL_HOMEBREW_DEPENDENCIES=(
  basedpyright               # python: https://docs.basedpyright.com/latest/installation/command-line-and-language-server/#__tabbed_2_2
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
  @astrojs/language-server              # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#astro
  @mdx-js/language-service              # TS server for MDX: https://github.com/mdx-js/mdx-analyzer/tree/main/packages/typescript-plugin
  @tailwindcss/language-server          # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#tailwindcss
  bash-language-server                  # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#bashls
  css-variables-language-server         # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#css_variables
  cssmodules-language-server            # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#cssmodules_ls
  prettier                              # for formatting lots of things
  typescript typescript-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#ts_ls
  vls                                   # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vuels
  vscode-langservers-extracted          # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#eslint
  vscode-langservers-extracted          # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#astro
  vscode-langservers-extracted          # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#jsonls
  yaml-language-server                  # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#yamlls
)

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
