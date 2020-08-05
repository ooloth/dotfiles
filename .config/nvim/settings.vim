" ------------------------------------------------------------------------
" CLIPBOARD
" ------------------------------------------------------------------------

" Copy/paste between Vim and everything else
set clipboard+=unnamed  " use the clipboards of vim and win
set paste               " Paste from a windows or from vim
set go+=a               " Visual selection automatically copied to the clipboard

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

set noerrorbells  " shhhhh

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

"Return to normal mode
set timeoutlen=500 "faster action after keypress (but still time for double)

" Give more space for displaying messages.
" set cmdheight=2

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

" Enable mouse
set mouse=a

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

syntax enable
" filetype on
" filetype plugin on
" filetype indent on
" set redrawtime=10000

set re=0 " https://github.com/HerringtonDarkholme/yats.vim#config

set termguicolors
set background=dark

let g:gruvbox_italic=1
let g:gruvbox_contrast_dark='medium'

colorscheme gruvbox
" colorscheme dracula
" colorscheme dogrun
" colorscheme deus
" colorscheme edge
" colorscheme onedark
" colorscheme xcodedark

" ------------------------------------------------------------------------
" CURSOR
" ------------------------------------------------------------------------

set scrolloff=12 "keep cursor this many lines away from top/bottom

" Cursor line
set cursorline
autocmd InsertEnter * set nocursorline
autocmd InsertLeave * set cursorline

" ------------------------------------------------------------------------
" SEARCH
" ------------------------------------------------------------------------

" Current file search
set hlsearch   " highlight search terms (manually remove with :nohl)
set incsearch  " show search matches while typing
set ignorecase " ignore case when searching (if search is lowercase)
set smartcase  " override above and match case (if search includes uppercase)

" Search file names with ':find'" (use * to make fuzzy and tab to autocomplete)
set nocompatible " limit search to this project
set path+=**     " search all subdirectories
set wildmenu     " show command line tab completion matches on one line

" ------------------------------------------------------------------------
" AIRLINE
" ------------------------------------------------------------------------

set showtabline=2 " Always show tabs
set noshowmode    " No need for --INSERT-- anymore

" ------------------------------------------------------------------------
" LIVE CONFIG RELOAD
" ------------------------------------------------------------------------

" Source init.vim again whenever I save changes to it
autocmd BufWritePost .config/nvim/mappings.vim source .config/nvim/init.vim
autocmd BufWritePost .config/nvim/plugins.vim source .config/nvim/init.vim
autocmd BufWritePost .config/nvim/settings.vim source .config/nvim/init.vim
autocmd BufWritePost .config/nvim/init.vim source %
