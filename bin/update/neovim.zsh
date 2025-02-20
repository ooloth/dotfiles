#!/usr/bin/env zsh

source "$DOTFILES/config/zsh/utils.zsh"

info "🧃 Installing lsp servers, linters and formatters"

# TODO: need to add all these tools to the PATH for neovim to find?

# Astro
npm i -g @astrojs/language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#astro

# Bash
brew install shellcheck
npm i -g bash-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#bashls

# CSS
npm i -g vscode-langservers-extracted # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#astro
npm i -g css-variables-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#css_variables
npm i -g cssmodules-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#cssmodules_ls
npm i -g @tailwindcss/language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#tailwindcss

# HTML/XML
brew install tidy-html5 # for linting html + xml

# Lua
brew install lua-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#lua_ls
brew install stylua # see: https://github.com/JohnnyMorganz/StyLua?tab=readme-ov-file#homebrew

# Markdown
brew install marksman # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#marksman

# Python
npm i -g pyright
brew install ruff

# Terraform
brew install hashicorp/tap/terraform-ls # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#terraformls
brew install tflint # https://github.com/terraform-linters/tflint

# TOML
cargo install --features lsp --locked taplo-cli # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#taplo

# TypeScript / JavaScript
npm i -g vscode-langservers-extracted # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#eslint
npm i -g typescript typescript-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#ts_ls

# Yaml
npm i -g yaml-language-server # see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#yamlls

info "🧃 Restoring Lazy plugin versions from lazy-lock.json"
NVIM_APPNAME=nvim-ide nvim --headless "+Lazy! restore" +qa
