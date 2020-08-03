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
" Plug 'vim-airline/vim-airline-themes'

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

let mapleader = " "
set noerrorbells  " shhhhh

" Backups
set hidden        " persist buffers in the background
set history=1000  " remember more commands and search history
set nobackup      " rely on git-based version control
set noswapfile
set nowritebackup " some servers have issues with backup files
set undodir=~/.vim/undodir
set undofile
set undolevels=200 " make more changes undoable

" ------------------------------------------------------------------------
" NAVIGATION
" ------------------------------------------------------------------------

" Line numbers
set number
set relativenumber

" Keep cursor near the middle of the screen
nnoremap n nzz
nnoremap N Nzz
nnoremap } }zz
nnoremap { {zz
nnoremap G Gzz
nnoremap i zzi
set scrolloff=15 "keep cursor this many lines away from top/bottom

""Cursor line
" set cursorline
" hi cursorline cterm=none term=none
" highlight CursorLine ctermbg=red guibg=#6272a4
" highlight CursorLine guibg=#303000 ctermbg=234
" set t_Co=256
" :highlight CursorLine ctermbg=LightBlue
" :autocmd InsertEnter * set nocursorline
" :autocmd InsertLeave * set cursorline

"Show file tree
set encoding=UTF-8
nmap <space>e :Lexplore<CR>

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

" Enable mouse
set mouse=a

" ------------------------------------------------------------------------
" LINTING & FORMATTING
" ------------------------------------------------------------------------

"Indenting
filetype plugin indent on
set autoindent    " always set autoindenting on
set copyindent    " copy the previous indentation on autoindenting
set expandtab     "convert tabs to spaces
set shiftround    " use multiple of shiftwidth when indenting with '<' and '>'
set shiftwidth=2
set showmatch     " set show matching parenthesis
set smartindent
set softtabstop=2
set tabstop=2

"Line wrapping
set linebreak    " keep words intact when wrapping
" set colorcolumn=100
" highlight ColorColumn ctermbg=lightgrey guibg=lightgrey
" set textwidth=100

" ------------------------------------------------------------------------
" SYNTAX HIGHLIGHTING
" ------------------------------------------------------------------------

"Rescan the entire buffer when highlighting js, jsx, ts and tsx files
"https://thoughtbot.com/blog/modern-typescript-and-react-development-in-vim
autocmd BufEnter *.{js,jsx,ts,tsx} :syntax sync fromstart
autocmd BufLeave *.{js,jsx,ts,tsx} :syntax sync clear

syntax enable
set redrawtime=10000

if has('nvim') || has('termguicolors')
  set termguicolors
endif

let g:dracula_colorterm = 0
let g:dracula_italic = 0
colorscheme dracula

" Enable italics (must come after colorscheme)
let g:one_allow_italics = 1
let g:javascript_plugin_flow = 1

"Tweak syntax coloring
highlight Comment gui=italic cterm=italic ctermfg=darkgrey guifg=#6272a4
highlight Type gui=italic cterm=italic ctermfg=cyan
highlight htmlArg gui=italic cterm=italic
highlight Function ctermfg=green guifg=green

" ------------------------------------------------------------------------
" SEARCH
" ------------------------------------------------------------------------

" Search current file with '/' (remapped to 'f')
set ignorecase
set incsearch  "see incremental results while typing
nnoremap f /

set hlsearch   " highlight search terms (manually remove with :nohl)
set incsearch  " show search matches while typing
set ignorecase " ignore case when searching (if search is lowercase)
set smartcase  " override above and match case (if search includes uppercase)

" Search file names with ':find'
" (use * to make fuzzy and tab to autocomplete)
set nocompatible " limit search to this project
set path+=**     " search all subdirectories
set wildmenu     " show command line tab completion matches on one line

" Search all file names with fzf (mapped to 'ff'; like Cmd-P in VS Code)
nnoremap ff :Files<CR>
nnoremap <Leader>b :Buffers<Cr>

" Grep all file contents with fzf and ripgrep (like Cmd-Shift-f in VS Code)
nnoremap <Leader>g :Rg<Space>

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


" Give more space for displaying messages.
" set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Use tab for trigger completion with characters ahead and navigate.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

"View documentation pop-up for word under cursor
nnoremap <silent> K :call CocAction('doHover')<CR>

"Go to related details about word under cursor
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gr <Plug>(coc-references)

"Go to prev/next error in current file
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

"See all workspace errors and warnings
nnoremap <silent> <space>d :<C-u>CocList diagnostics<cr>

"See all symbols in workspace
nnoremap <silent> <space>s :<C-u>CocList -I symbols<cr>

"Rename symbol under cursor
nmap <leader>rn <Plug>(coc-rename)

"Prompt for how to autofix issue with word under cursor
nmap <leader>do <Plug>(coc-codeaction)

" ------------------------------------------------------------------------
" CUSTOM KEYBINDINGS
" ------------------------------------------------------------------------

"Disable arrow key navigation
noremap <Up> <nop>
noremap <Right> <nop>
noremap <Down> <nop>
noremap <Left> <nop>
inoremap <Up> <nop>
inoremap <Right> <nop>
inoremap <Down> <nop>
inoremap <Left> <nop>

"Return to normal mode
set timeoutlen=300 "faster action after keypress (but still time for double)

inoremap ii <Esc>
inoremap jj <Esc>
inoremap jk <Esc>
inoremap ;; <Esc>

noremap ;; <Esc>
" noremap <Shift> <Esc>

tnoremap <Esc> <C-\><C-n>
tnoremap ii <C-\><C-n>
tnoremap jj <C-\><C-n>
tnoremap jk <C-\><C-n>
tnoremap ;; <C-\><C-n>

"Navigate panes
noremap <C-h> <C-w>h
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l
noremap <Leader>h <C-w>h
noremap <Leader>j <C-w>j
noremap <Leader>k <C-w>k
noremap <Leader>l <C-w>l
tnoremap <Leader>h <C-\><C-n><C-w>h
tnoremap <Leader>j <C-\><C-n><C-w>j
tnoremap <Leader>k <C-\><C-n><C-w>k
tnoremap <Leader>l <C-\><C-n><C-w>l

"Open current file in new tab (to temporarily make it fullscreen)
"https://stackoverflow.com/a/15584901
noremap tt :tab split<CR>

"Show open windows (navigate list with C-j, C-k)
noremap <Leader>w :Windows<CR>

"Show undo tree
nnoremap <Leader>u :UndotreeShow<CR>

"Toggle comments
noremap <Leader>/ :Commentary<cr>

"Reformat comments
"https://stackoverflow.com/a/12718321/8802485
" nnoremap <Leader>f gqip

"Quick console logs
"https://vi.stackexchange.com/a/21896
nnoremap <Leader>L "ayiwoconsole.log('<C-R>a:', <C-R>a);<Esc>

"Exiting
noremap <Leader>q :q<CR>
noremap <Leader>qq :wq<CR>
noremap <Leader>Q :wq<CR>

set splitright
set splitbelow

" Make Y behave like D and C instead of yanking the entire line
nnoremap Y y$

" Copy/paste between Vim and everything else
set clipboard=unnamedplus


" If I wanted to stop inserting a comment character when pressing <Enter> in a
" comment line, this is how:
" set formatoptions-=cro

" Better nav for omnicomplete
inoremap <expr> <c-j> ("\<C-n>")
inoremap <expr> <c-k> ("\<C-p>")

inoremap kj <Esc>

nnoremap <TAB> :bnext<CR>       " TAB in normal mode will move to next buffer
nnoremap <S-TAB> :bprevious<CR> " SHIFT-TAB will go back

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

" Always show tabs
set showtabline=2

" We don't need to see things like -- INSERT -- anymore
set noshowmode

autocmd BufWritePre * :%s/\s\+$//e   " remove trailing whitespace on save
autocmd BufWritePost .vimrc source % " auto source when writing file
