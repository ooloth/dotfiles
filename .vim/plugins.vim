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
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/rainbow_parentheses.vim'
Plug 'jremmen/vim-ripgrep'
Plug 'liuchengxu/vim-which-key'
Plug 'mbbill/undotree'
Plug 'mhinz/vim-startify'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-commentary'
Plug 'vim-airline/vim-airline'
" Plug 'voldikss/vim-floaterm'

" Git
Plug 'tpope/vim-fugitive'

call plug#end()

"Automatically install missing plugins on startup
"https://github.com/ChristianChiarulli/nvim/blob/master/vim-plug/plugins.vim
autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif"

" ------------------------------------------------------------------------
" NETRW
" ------------------------------------------------------------------------

"Disable Netrw file tree
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

""Customize file tree
"let g:netrw_altv=1                              " open splits to the right
"let g:netrw_banner=0                            " disable banner
"let g:netrw_browse_split=4                      " open in non-tree window
"" let g:netrw_list_hide=netrw_gitignore#Hide()    " hide .gitignore files
"" let g:netrw_list_hide.=',\(^\?\s\s\)\zs\.\S\+'  " hide dot files
"let g:netrw_liststyle=3                         " use tree view
"let g:netrw_preview=1                           " vertical split preview
"let g:netrw_winsize=20                          " % of horizontal space

" TODO: customize which files are toggled as hidden by 'gh'
" let dotFiles = //
" let gitIgnoreFiles = //
" let npmFiles = //
" let gatsbyFiles = //
" let g:netrw_list_hide=dotFiles + gitIgnoreFiles + npmFiles + gatsbyFiles

"Delete abandoned Netrw buffers (e.g. preview windows)
" autocmd FileType netrw setl bufhidden=delete

" ------------------------------------------------------------------------
" DRACULA THEME
" ------------------------------------------------------------------------

let g:dracula_colorterm = 0
let g:dracula_italic = 0

" ------------------------------------------------------------------------
" FZF
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
  \ 'coc-explorer',
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

" ------------------------------------------------------------------------
" COC-YANK
" ------------------------------------------------------------------------

"Change coc-yank highlight color
hi HighlightedyankRegion term=bold ctermbg=green ctermfg=black guibg=#13354A

" ------------------------------------------------------------------------
" AIRLINE
" ------------------------------------------------------------------------

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

" ------------------------------------------------------------------------
" Which Key
" ------------------------------------------------------------------------

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

" ------------------------------------------------------------------------
" Rainbow Parentheses
" ------------------------------------------------------------------------

let g:rainbow#max_level = 16
let g:rainbow#pairs = [['(', ')'], ['[', ']'], ['{', '}']]

autocmd FileType * RainbowParentheses

" Activate based on file type
augroup rainbow_lisp
  autocmd!
  autocmd FileType javascript,javascriptreact,typescript,typescriptreact  RainbowParentheses
augroup END

" ------------------------------------------------------------------------
" STARTIFY
"
" Useful commands: ':SSave', ':SLoad', ':SDelete'
"
" https://github.com/mhinz/vim-startify/blob/master/doc/startify.txt
" https://www.chrisatmachine.com/Neovim/11-startify/
" ------------------------------------------------------------------------

let g:startify_change_to_vcs_root = 1     " change cwd to project root on open
let g:startify_enable_special = 0         " get rid of empty buffers on quit
let g:startify_fortune_use_unicode = 1    " if I want Unicode
let g:startify_session_autoload = 1 " automatically restart sessions if dir has Sessions.vim
let g:startify_session_delete_buffers = 1 " let Startify take care of buffers
let g:startify_session_dir = '/Users/Michael/.vim/sessions'
let g:startify_session_persistence = 1    " automatically update sessions on quit
let g:startify_session_sort = 0           " sort sessions by date modified

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
  \ { 'type': 'dir', 'header': [' Recently opened in '. s:getDir()] },
  \ { 'type': 'bookmarks', 'header': [' Bookmarks'] },
  \ ]

let g:startify_bookmarks = [
  \ { 'e': '~/Sites/ecobee/consumer-website/' },
  \ { 'm': '~/Sites/projects/michaeluloth.com/' },
  \ { 'g': '~/Sites/projects/gatsbytutorials.com/' },
  \ { 'd': '~/Sites/projects/dotfiles/' },
  \ { 'p': '~/Sites/projects/' },
  \ { 'u': '~/Sites/mu/' },
  \ { 'c': '~/Sites/cc/' },
  \ { 's': '~/Sites/' },
  \ ]

" Unicode art generator:
" http://patorjk.com/software/taag/#p=display&f=Graffiti&t=Type%20Something%20
"
" let g:startify_custom_header = [
"   \ '   _  __     _         __  ___         __     ___ ',
"   \ '  / |/ /  __(_)_ _    /  |/  /__ _____/ /    |_  |',
"   \ ' /    / |/ / /  ` \  / /|_/ / _ `/ __/ _ \  / __/ ',
"   \ '/_/|_/|___/_/_/_/_/ /_/  /_/\_,_/\__/_//_/ /____/ ',
"   \ ]

" Prevent coc-explorer from staying stuck in the last session's CWD after :SClose
autocmd User Startified :silent CocRestart

" ------------------------------------------------------------------------
" FLOATERM
"
" Useful commands: ...
"
" https://github.com/voldikss/vim-floaterm
" https://www.chrisatmachine.com/Neovim/16-floaterm/
" ------------------------------------------------------------------------

" TODO: get this working...
" let g:floaterm_gitcommit='floaterm'
" let g:floaterm_autoinsert=1
" let g:floaterm_width=0.8
" let g:floaterm_height=0.8
" let g:floaterm_wintitle=0
" let g:floaterm_autoclose=1

