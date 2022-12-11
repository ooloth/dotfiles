" Write buffer after leaving insert mode or changing text in normal mode
autocmd InsertLeave,TextChanged * update

set clipboard+=unnamedplus " use the system clipboard for everything

set completeopt=menuone,noinsert,noselect
set shortmess+=c                           " don't pass messages to |ins-completion-menu|

" Cursor line

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
