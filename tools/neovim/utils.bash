#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="neovim"
export TOOL_UPPER="Neovim"
export TOOL_COMMAND="nvim"
export TOOL_PACKAGE="neovim"
export TOOL_EMOJI="🦸"
export TOOL_CONFIG_DIR="${HOME}/.config/nvim"

export TOOL_NPM_DEPENDENCIES=(
  @astrojs/language-server      # astro: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#astro
  @mdx-js/language-service      # mdx: https://github.com/mdx-js/mdx-analyzer/tree/main/packages/typescript-plugin
  @olrtg/emmet-language-server  # emmet: ...
  css-variables-language-server # css: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#css_variables
  cssmodules-language-server    # css modules: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#cssmodules_ls
  neovim                        # neovim: ...
  pug-lint                      # pug: ...
  svelte-language-server        # svelte: ...
)

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
