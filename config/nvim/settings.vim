" ------------------------------------------------------------------------
" BUFFERS
" ------------------------------------------------------------------------

set hidden     " persist buffers in the background
set splitright
set splitbelow

" Write buffer after leaving insert mode or changing text in normal mode
autocmd InsertLeave,TextChanged * update

" ------------------------------------------------------------------------
" CLIPBOARD
" ------------------------------------------------------------------------

set clipboard+=unnamedplus " use the system clipboard for everything

" ------------------------------------------------------------------------
" COMPLETION
" ------------------------------------------------------------------------

set completeopt=menuone,noinsert,noselect
set shortmess+=c                           " don't pass messages to |ins-completion-menu|

" ------------------------------------------------------------------------
" CURSOR
" ------------------------------------------------------------------------

set scrolloff=22 " keep cursor this many lines away from top/bottom

" Cursor line
set cursorline
autocmd InsertEnter * set nocursorline
autocmd InsertLeave * set cursorline

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
set wrap
set linebreak     " keep words intact when wrapping
set breakindent   " wrap with same indentation

" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" ------------------------------------------------------------------------
" HISTORY
" ------------------------------------------------------------------------

set history=1000           " remember more commands and search history
set nobackup               " rely on git-based version control
set noswapfile
set nowritebackup          " some servers have issues with backup files
set undodir=~/.vim/undodir
set undofile
set undolevels=200         " make more changes undoable

" ------------------------------------------------------------------------
" SEARCH
" ------------------------------------------------------------------------

" Current file search
set hlsearch
set incsearch  " show search matches while typing
set ignorecase " ignore case when searching...
set smartcase  " ...unless search includes uppercase letters

" Search file names with ':find'" (use * to make fuzzy and tab to autocomplete)
" set path+=**;     " search all subdirectories (https://stackoverflow.com/a/52126548/8802485)
" set suffixesadd=.js,.ts,.tsx
" set wildmode=longest,list,full

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

let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

let g:onedark_terminal_italics=1
colorscheme onedark

" ------------------------------------------------------------------------
" UX
" ------------------------------------------------------------------------

set cmdheight=2
set confirm                                " instead of failing, ask me what to do
set lazyredraw                             " wait to redraw screen until macro is complete
set noerrorbells                           " shhhhh
set signcolumn=yes
set updatetime=50                          " reduce lag (default is 4000)
set timeoutlen=500                         " respond faster to keypresses (default is 1000)
set ttimeoutlen=1

augroup highlight_yank
    autocmd!
    autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout = 700})
augroup END
