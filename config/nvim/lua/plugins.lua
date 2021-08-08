local cmd = vim.cmd
local opt = vim.opt
local has = vim.fn.has

cmd([[
" ------------------------------------------------------------------------
" INSTALL PLUGINS
" ------------------------------------------------------------------------

" Install vim-plug if not already installed
" https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" Neovim LSP
Plug 'neovim/nvim-lspconfig'
Plug 'tjdevries/nlua.nvim'
Plug 'tjdevries/lsp_extensions.nvim'

" Syntax highlighting
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
" Plug 'drewtempelmeyer/palenight.vim'
Plug 'gruvbox-community/gruvbox'

" Linting
Plug 'prettier/vim-prettier', { 'do': 'yarn install' }

" Completion
Plug 'nvim-lua/completion-nvim'

" Search
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'mbbill/undotree'

" File tree
Plug 'vifm/vifm.vim'

" Git
Plug 'tpope/vim-fugitive'

" Tests
" Plug 'vim-test/vim-test'

" Organization
Plug 'Asheq/close-buffers.vim'
Plug 'liuchengxu/vim-which-key'
Plug 'mhinz/vim-startify'
Plug 'vim-airline/vim-airline'

" Convenience
Plug 'mattn/emmet-vim'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'               " extends . functionality to plugins like vim-surround
Plug 'norcalli/nvim-colorizer.lua'
" Plug 'alvan/vim-closetag'
" Plug 'tpope/vim-unimpaired'           " pairs of '[' and ']' mappings
" Plug 'christoomey/vim-tmux-navigator' " navigate seamlessly between vim + tmux splits
" Plug 'christoomey/vim-tmux-runner'

call plug#end()

" Automatically install missing plugins on startup
" https://github.com/ChristianChiarulli/nvim/blob/master/vim-plug/plugins.vim
autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif"

" ------------------------------------------------------------------------
" AIRLINE
" ------------------------------------------------------------------------

set showtabline=2 " Always show tabs
set noshowmode    " No need for --INSERT-- anymore

let g:airline_focuslost_inactive = 1
let g:airline_highlighting_cache = 1
let g:airline_left_sep=''                  " no arrows pointing right
let g:airline_powerline_fonts = 1          " use nerd font devicons
let g:airline_right_sep=''                 " no arrows pointing left
let g:airline#extensions#branch#format = 1 " show only tail of branch name
let g:airline#extensions#coc#enabled = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'

" Replace some unwanted symbols with empty space
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

let g:airline_symbols.linenr = ' '
let g:airline_symbols.maxlinenr = ''

" ------------------------------------------------------------------------
" COLORIZER
" ------------------------------------------------------------------------

set termguicolors " repeated here to avoid a plugin error
lua require'colorizer'.setup()

" ------------------------------------------------------------------------
" LSP
" ------------------------------------------------------------------------

let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']
" lua require'lspconfig'.tsserver.setup{ on_attach=require'completion'.on_attach }

lua << EOF
require'lspconfig'.tsserver.setup {
    filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
    on_attach = require'completion'.on_attach,
    root_dir = require('lspconfig/util').root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
    -- This makes sure tsserver is not used for formatting (I prefer prettier)
    settings = {documentFormatting = false},
    handlers = {
        ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
            virtual_text = {spacing = 0, prefix = ""},
            signs = true,
            underline = true,
            update_in_insert = true
        })
    }
 }
EOF

" ------------------------------------------------------------------------
" LSP EXTENSIONS
" ------------------------------------------------------------------------

augroup inlay_hints
    autocmd!
    autocmd BufEnter,BufWinEnter,TabEnter * :lua require'lsp_extensions'.inlay_hints{}
augroup END

" ------------------------------------------------------------------------
" NETRW
" ------------------------------------------------------------------------

" Disable Netrw file tree
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

"------------------------------------------------------------------------
" TELESCOPE
" ------------------------------------------------------------------------

lua << EOF
require('telescope').setup{
  defaults = {
    file_sorter = require('telescope.sorters').get_fzy_sorter,
    file_ignore_patterns = { 'yarn.lock', '**/*.snap', '.gitignore' },
    file_previewer = require'telescope.previewers'.vim_buffer_cat.new,
    grep_previewer = require'telescope.previewers'.vim_buffer_vimgrep.new,
    qflist_previewer = require'telescope.previewers'.vim_buffer_qflist.new,
  }
}
EOF

" ------------------------------------------------------------------------
" TREESITTER
" ------------------------------------------------------------------------

lua << EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "bash", "css", "graphql", "html", "javascript", "jsdoc", "json", "lua", "php", "toml", "tsx", "typescript", "vue", "yaml" },
}
EOF

" Syntax highlighting
lua <<EOF
require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    custom_captures = {
      -- Highlight the @foo.bar capture group with the "Identifier" highlight group.
      ["foo.bar"] = "Identifier",
    },
  },
}
EOF

" Incremental selection (based on the named nodes from the grammar)
lua <<EOF
require'nvim-treesitter.configs'.setup {
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
}
EOF

" Indentation
lua <<EOF
require'nvim-treesitter.configs'.setup {
  indent = {
    enable = true
  }
}
EOF

" ------------------------------------------------------------------------
" VIFM VIM
" ------------------------------------------------------------------------

let g:vifm_replace_netrw=1

" ------------------------------------------------------------------------
" VIM CLOSETAG
" ------------------------------------------------------------------------

" These are the file extensions where this plugin is enabled.
let g:closetag_filenames = '*.html,*.xhtml,*.jsx,*.js,*.tsx'

" This will make the list of non-closing tags self-closing in the specified files.
let g:closetag_xhtml_filenames = '*.xml,*.xhtml,*.jsx,*.js,*.tsx'

" These are the file types where this plugin is enabled.
let g:closetag_filetypes = 'html,xhtml,jsx,js,tsx'

" This will make the list of non-closing tags self-closing in the specified files.
let g:closetag_xhtml_filetypes = 'xml,xhtml,jsx,js,tsx'

" This will make the list of non-closing tags case-sensitive (e.g. `<Link>` will be closed while `<link>` won't.)
let g:closetag_emptyTags_caseSensitive = 1

" Disables auto-close if not in a "valid" region (based on filetype)
let g:closetag_regions = {
    \ 'typescript.tsx': 'jsxRegion,tsxRegion',
    \ 'javascript.jsx': 'jsxRegion',
    \ }

" Shortcut for closing tags, default is '>'
let g:closetag_shortcut = '>'

" Add > at current position without closing the current tag, default is ''
let g:closetag_close_shortcut = '<leader>>'

" ------------------------------------------------------------------------
" VIM EMMET
" ------------------------------------------------------------------------

let g:user_emmet_leader_key='<C-x>'

" ------------------------------------------------------------------------
" VIM FUGITIVE
"
" See: https://github.com/tpope/vim-fugitive/issues/1080#issuecomment-521100430
" ------------------------------------------------------------------------

" Remove default y<C-G> mapping causing delays when using Y to move left
let g:nremap = {'y': ''}
let g:xremap = {'y': ''}
let g:oremap = {'y': ''}

" ------------------------------------------------------------------------
" VIM PRETTIER
" ------------------------------------------------------------------------

" let g:prettier#autoformat=1
let g:prettier#autoformat_require_pragma=0
let g:prettier#autoformat_config_present=1

" ------------------------------------------------------------------------
" VIM SURROUND
"
" See: https://github.com/tpope/vim-surround/issues/269
" ------------------------------------------------------------------------

" Customizing mappings to avoid default Y maps delaying my Y movements
let g:surround_no_mappings=1

nmap ds  <Plug>Dsurround
nmap cs  <Plug>Csurround
nmap cS  <Plug>CSurround
nmap gs  <Plug>Ysurround
nmap gS  <Plug>YSurround
nmap gss <Plug>Yssurround
nmap gSs <Plug>YSsurround
nmap gSS <Plug>YSsurround
xmap S   <Plug>VSurround
" xmap gS  <Plug>VgSurround

" ------------------------------------------------------------------------
" VIM TEST
" ------------------------------------------------------------------------

" let test#strategy = 'neovim'
" let test#neovim#term_position = 'vert'

" ------------------------------------------------------------------------
" WHICH KEY
" ------------------------------------------------------------------------

" Define a separator
let g:which_key_sep='→'

" Not a fan of floating windows for this
let g:which_key_use_floating_win=0

" Change the colors if you want
highlight default link WhichKey          Operator
highlight default link WhichKeySeperator DiffAdded
highlight default link WhichKeyGroup     Identifier
highlight default link WhichKeyDesc      Function

" Hide status line
autocmd! FileType which_key
autocmd  FileType which_key set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 noshowmode ruler
]])
