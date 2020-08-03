" ------------------------------------------------------------------------
" INSTALL PLUGINS
" ------------------------------------------------------------------------

"Install vim-plug if not already installed
"https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'jremmen/vim-ripgrep'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'mbbill/undotree'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline'
Plug 'liuchengxu/vim-which-key'

call plug#end()

"Automatically install missing plugins on startup
"https://github.com/ChristianChiarulli/nvim/blob/master/vim-plug/plugins.vim
autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif"

" ------------------------------------------------------------------------
" GENERAL
" ------------------------------------------------------------------------

"Customize file tree
let g:netrw_altv=1                              " open splits to the right
let g:netrw_banner=0                            " disable banner
let g:netrw_browse_split=4                      " open in non-tree window
" let g:netrw_list_hide=netrw_gitignore#Hide()    " hide .gitignore files
" let g:netrw_list_hide.=',\(^\?\s\s\)\zs\.\S\+'  " hide dot files
let g:netrw_liststyle=3                         " use tree view
let g:netrw_preview=1                           " vertical split preview
let g:netrw_winsize=20                          " % of horizontal space

" TODO: customize which files are toggled as hidden by 'gh'
" let dotFiles = //
" let gitIgnoreFiles = //
" let npmFiles = //
" let gatsbyFiles = //
" let g:netrw_list_hide=dotFiles + gitIgnoreFiles + npmFiles + gatsbyFiles

"Delete abandoned Netrw buffers (e.g. preview windows)
autocmd FileType netrw setl bufhidden=delete

let g:dracula_colorterm = 0
let g:dracula_italic = 0

"Change coc-yank highlight color
hi HighlightedyankRegion term=bold ctermbg=green ctermfg=black guibg=#13354A

" ------------------------------------------------------------------------
" SEARCH
" ------------------------------------------------------------------------

" ripgrep
" if executable('rg')
"   let g:rg_derive_root='true'
" endif
" set grepprg=rg\ --vimgrep\ --smart-case\ --hidden\ --follow

" ------------------------------------------------------------------------
" CONQUER OF COMPLETION
" ------------------------------------------------------------------------

" Coc plugins to automatically install and update in any project
let g:coc_global_extensions = [
  \ 'coc-css',
  \ 'coc-json',
  \ 'coc-yaml'
  \ ]

if isdirectory('./node_modules')
  "Activate prettier (if installed)
  if isdirectory('./node_modules/prettier')
    let g:coc_global_extensions += ['coc-prettier']
  endif

  "Activate eslint (if installed)
  if isdirectory('./node_modules/eslint')
    let g:coc_global_extensions += ['coc-eslint']
  endif

  "Activate flow or typescript (if installed), but never both
  if isdirectory('./node_modules/flow-bin')
    let g:coc_global_extensions += ['coc-flow']
  elseif isdirectory('./node_modules/typescript')
    let g:coc_global_extensions += ['coc-tsserver']
  endif

  "Activate tailwind (if installed)
  if isdirectory('./node_modules/tailwindcss')
    let g:coc_global_extensions += ['coc-tailwindcss']
  endif
endif


" Airline
let g:airline#extensions#tabline#enabled = 1
let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'
let g:airline_highlighting_cache = 1
let g:airline_focuslost_inactive = 1

" Replace some unwanted symbols with empty space
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

let g:airline_symbols.linenr = ' '
let g:airline_symbols.maxlinenr = '  ln'

" Define a separator
let g:which_key_sep = '→'

" Not a fan of floating windows for this
let g:which_key_use_floating_win = 0

" Change the colors if you want
highlight default link WhichKey          Operator
highlight default link WhichKeySeperator DiffAdded
highlight default link WhichKeyGroup     Identifier
highlight default link WhichKeyDesc      Function

" Hide status line
autocmd! FileType which_key
autocmd  FileType which_key set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 noshowmode ruler

