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

" Enable mouse
set mouse=a

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

syntax enable
set redrawtime=10000

if has('nvim') || has('termguicolors')
  set termguicolors
endif

colorscheme dracula

" Enable italics (must come after colorscheme)
let g:one_allow_italics = 1
let g:javascript_plugin_flow = 1

"Tweak syntax coloring
highlight Comment gui=italic cterm=italic ctermfg=darkgrey guifg=#6272a4
highlight Type gui=italic cterm=italic ctermfg=cyan
highlight htmlArg gui=italic cterm=italic
highlight Function ctermfg=green guifg=green

set ignorecase
set incsearch  "see incremental results while typing

set hlsearch   " highlight search terms (manually remove with :nohl)
set incsearch  " show search matches while typing
set ignorecase " ignore case when searching (if search is lowercase)
set smartcase  " override above and match case (if search includes uppercase)

" Search file names with ':find'
" (use * to make fuzzy and tab to autocomplete)
set nocompatible " limit search to this project
set path+=**     " search all subdirectories
set wildmenu     " show command line tab completion matches on one line

" Give more space for displaying messages.
" set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

"Return to normal mode
set timeoutlen=300 "faster action after keypress (but still time for double)

set splitright
set splitbelow

" Copy/paste between Vim and everything else
" set clipboard=unnamedplus


" If I wanted to stop inserting a comment character when pressing <Enter> in a
" comment line, this is how:
" set formatoptions-=cro

" Always show tabs
set showtabline=2

" We don't need to see things like -- INSERT -- anymore
set noshowmode

"Rescan the entire buffer when highlighting js, jsx, ts and tsx files
"https://thoughtbot.com/blog/modern-typescript-and-react-development-in-vim
autocmd BufEnter *.{js,jsx,ts,tsx} :syntax sync fromstart
autocmd BufLeave *.{js,jsx,ts,tsx} :syntax sync clear

autocmd BufWritePre * :%s/\s\+$//e   " remove trailing whitespace on save
autocmd BufWritePost .vimrc source % " auto source when writing file

