#!/usr/bin/env zsh

source "$DOTFILES/config/zsh/utils.zsh"

info "🧃 Updating Neovim lsp servers, linters and formatters"

# TODO: need to add any of these tools to the PATH manually for neovim to find?
# NOTE: all brew installed tools also need to be listed in Brewfile so brew bundle won't remove them

# Astro
npm i -g @astrojs/language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#astro

# Bash
brew install shellcheck
brew install shfmt
npm i -g bash-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#bashls

# CSS
npm i -g vscode-langservers-extracted # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#astro
npm i -g css-variables-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#css_variables
npm i -g cssmodules-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#cssmodules_ls
npm i -g @tailwindcss/language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#tailwindcss

# HTML/XML
brew install tidy-html5 # for linting html + xml
npm i -g prettier # for formatting lots of things

# JSON
npm i -g vscode-langservers-extracted # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#jsonls

# Lua
brew install lua-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#lua_ls
brew install stylua # see: https://github.com/JohnnyMorganz/StyLua?tab=readme-ov-file#homebrew

# Markdown / MDX
brew install marksman # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#marksman
npm i -g @mdx-js/language-service

# Python
npm i -g pyright
brew install basedpyright # see: https://docs.basedpyright.com/latest/installation/command-line-and-language-server/#__tabbed_2_2
brew install ruff

# Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform # see: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
brew install hashicorp/tap/terraform-ls # see: https://github.com/hashicorp/terraform-ls/blob/main/docs/installation.md
brew install tflint # https://github.com/terraform-linters/tflint

# TOML
cargo install --features lsp --locked taplo-cli # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#taplo

# TypeScript / JavaScript
npm i -g vscode-langservers-extracted # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#eslint
npm i -g typescript typescript-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#ts_ls

# Vue
npm i -g vls # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vuels

# Yaml
npm i -g yaml-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#yamlls

info "🧃 Restoring Lazy plugin versions from lazy-lock.json"
NVIM_APPNAME=nvim-ide nvim --headless "+Lazy! restore" +qa
