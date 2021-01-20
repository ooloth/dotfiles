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
Plug 'joshdick/onedark.vim'
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
Plug 'justinmk/vim-dirvish'

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
Plug 'alvan/vim-closetag'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'               " extends . functionality to plugins like vim-surround
Plug 'norcalli/nvim-colorizer.lua'
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
lua require'lspconfig'.tsserver.setup{ on_attach=require'completion'.on_attach }

" ------------------------------------------------------------------------
" NETRW
" ------------------------------------------------------------------------

" Disable Netrw file tree
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

" ------------------------------------------------------------------------
" STARTIFY
" ------------------------------------------------------------------------

" Useful commands: ':SSave', ':SLoad', ':SDelete'

" https://github.com/mhinz/vim-startify/blob/master/doc/startify.txt
" https://www.chrisatmachine.com/Neovim/11-startify/

let g:startify_change_to_vcs_root = 1     " change cwd to project root on open
let g:startify_enable_special = 0         " get rid of empty buffers on quit
let g:startify_fortune_use_unicode = 1    " if I want Unicode
let g:startify_session_autoload = 1       " automatically restart sessions if dir has Sessions.vim
let g:startify_session_delete_buffers = 1 " let Startify take care of buffers
let g:startify_session_dir = '$HOME/.config/nvim/sessions'
let g:startify_session_persistence = 1    " automatically update sessions on quit
let g:startify_session_sort = 0           " sort sessions by date modified
let g:startify_update_oldfiles = 1        " keep Startify up to date as I work

" returns all modified files of the current git repo
" `2>/dev/null` makes the command fail quietly, so that when we are not
" in a git repo, the list will be empty
function! s:gitModified()
  let files = systemlist('git ls-files -m 2>/dev/null')
  return map(files, "{'line': v:val, 'path': v:val}")
endfunction

" same as above, but show untracked files, honouring .gitignore
function! s:gitUntracked()
  let files = systemlist('git ls-files -o --exclude-standard 2>/dev/null')
  return map(files, "{'line': v:val, 'path': v:val}")
endfunction

" Return just the tail path of the current working directory
" https://vi.stackexchange.com/a/15047
function! s:getDir()
  return fnamemodify(getcwd(), ':t')
endfunction

let g:startify_lists = [
  \ { 'type': 'sessions',  'header': [' Sessions'] },
  \ { 'type': function('s:gitModified'), 'header': [' [Git] Modified in current branch'] },
  \ { 'type': function('s:gitUntracked'), 'header': [' [Git] Untracked in current branch'] },
  \ { 'type': 'bookmarks', 'header': [' Bookmarks'] },
  \ ]

let g:startify_bookmarks = [
  \ { 'e': '~/Repos/ecobee/consumer-website/' },
  \ { 'd': '~/Repos/ooloth/dotfiles/' },
  \ { 'm': '~/Repos/ooloth/michaeluloth.com/' },
  \ { 'g': '~/Repos/ooloth/gatsbytutorials.com/' },
  \ { 's': '~/Repos/' },
  \ ]

" Create viminfo file (for new installs)
" https://github.com/ChristianChiarulli/nvim/issues/5#issuecomment-625933872
" set viminfo='100,n$HOME/.config/nvim/autoload/plugged/vim-startify/test/viminfo'

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
" VIM DIRVISH
" ------------------------------------------------------------------------

let g:dirvish_mode = ':sort ,^.*[\/],'

augroup dirvish_config
  autocmd!

  " Map `t` to open in new tab.
  autocmd FileType dirvish
    \  nnoremap <silent><buffer> t :call dirvish#open('tabedit', 0)<CR>
    \ |xnoremap <silent><buffer> t :call dirvish#open('tabedit', 0)<CR>

  " Map `gr` to reload.
  autocmd FileType dirvish nnoremap <silent><buffer>
    \ gr :<C-U>Dirvish %<CR>

  " Map `gh` to hide dot-prefixed files.  Press `R` to "toggle" (reload).
  autocmd FileType dirvish nnoremap <silent><buffer>
    \ gh :silent keeppatterns g@\v/\.[^\/]+/?$@d _<cr>:setl cole=3<cr>
augroup END

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

" Delay popping up the window
let g:which_key_timeout=500

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
