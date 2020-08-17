" ------------------------------------------------------------------------
" CLIPBOARD
" ------------------------------------------------------------------------

" Copy/paste between Vim and everything else
set clipboard+=unnamedplus  " use the system clipboard for everything
set go+=a                   " Visual selection automatically copied to the clipboard

" ------------------------------------------------------------------------
" Undo History
" ------------------------------------------------------------------------

set history=1000  " remember more commands and search history
set nobackup      " rely on git-based version control
set noswapfile
set nowritebackup " some servers have issues with backup files
set undodir=~/.vim/undodir
set undofile
set undolevels=200 " make more changes undoable

" ------------------------------------------------------------------------
" UX
" ------------------------------------------------------------------------

set noerrorbells   " shhhhh
set updatetime=300 " reduce lag (default is 4000)
set timeoutlen=500 " respond faster to keypresses (default is 1000)
set ttimeoutlen=10

" ------------------------------------------------------------------------
" BUFFERS
" ------------------------------------------------------------------------

set hidden        " persist buffers in the background
set splitright
set splitbelow

" ------------------------------------------------------------------------
" NAVIGATION
" ------------------------------------------------------------------------

" Line numbers
set number
set relativenumber

" Disable mouse
set mouse=

" ------------------------------------------------------------------------
" FORMATTING
" ------------------------------------------------------------------------

set encoding=UTF-8

"Indenting
set autoindent    " always set autoindenting on
set copyindent    " copy the previous indentation on autoindenting
set expandtab     " convert tabs to spaces
set shiftround    " use multiple of shiftwidth when indenting with '<' and '>'
set shiftwidth=2
set showmatch     " set show matching parenthesis
set smartindent
set softtabstop=2
set tabstop=2

"Line wrapping
set linebreak     " keep words intact when wrapping
set textwidth=100 " match ecobee's max-width

" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" ------------------------------------------------------------------------
" SYNTAX HIGHLIGHTING
" ------------------------------------------------------------------------

filetype on
filetype plugin on
filetype indent on
syntax enable

set termguicolors
set background=dark
set re=0            " https://github.com/HerringtonDarkholme/yats.vim#config

let g:gruvbox_italic=1
let g:gruvbox_contrast_dark='medium'
colorscheme gruvbox

" ------------------------------------------------------------------------
" CURSOR
" ------------------------------------------------------------------------

set scrolloff=12 " keep cursor this many lines away from top/bottom

" Cursor line
set cursorline
autocmd InsertEnter * set nocursorline
autocmd InsertLeave * set cursorline

" Indicate which window is active
augroup HighlightActiveWindow
    autocmd!
    autocmd WinEnter * set cursorline relativenumber
    autocmd WinLeave * set nocursorline norelativenumber
augroup END

" ------------------------------------------------------------------------
" SEARCH
" ------------------------------------------------------------------------

" Current file search
set hlsearch   " highlight search terms (manually remove with :nohl)
set incsearch  " show search matches while typing
set ignorecase " ignore case when searching...
set smartcase  " ...unless search includes uppercase letters

" Search file names with ':find'" (use * to make fuzzy and tab to autocomplete)
set path+=**;     " search all subdirectories (https://stackoverflow.com/a/52126548/8802485)
set suffixesadd=.js,.ts,.tsx
" set wildmode=longest,list,full

" ------------------------------------------------------------------------
" AIRLINE
" ------------------------------------------------------------------------

set showtabline=2 " Always show tabs
set noshowmode    " No need for --INSERT-- anymore

