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

Plug 'ryanoasis/vim-devicons'

" Syntax (https://github.com/MaxMEllon/vim-jsx-pretty#installation)
Plug 'HerringtonDarkholme/yats.vim' " highlight TS + TSX
Plug 'maxmellon/vim-jsx-pretty'     " highlight JSX
Plug 'yuezk/vim-js'                 " highlight JS + Flow
Plug 'sheerun/vim-polyglot'         " must be last syntax plugin

" Highlighting
Plug 'morhetz/gruvbox'

" Intellisense
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Search
Plug 'jremmen/vim-ripgrep'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'mbbill/undotree'

" Git
Plug 'tpope/vim-fugitive'
Plug 'idanarye/vim-merginal'

" Tests
Plug 'vim-test/vim-test'

" Organization
Plug 'Asheq/close-buffers.vim'
Plug 'liuchengxu/vim-which-key'
Plug 'mhinz/vim-startify'
Plug 'vim-airline/vim-airline'

" Convenience
Plug 'alvan/vim-closetag'
Plug 'christoomey/vim-tmux-navigator' " navigate seamlessly between vim + tmux splits
" Plug 'christoomey/vim-tmux-runner'
Plug 'metakirby5/codi.vim'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'               " extends . functionality to plugins like vim-surround
Plug 'tpope/vim-unimpaired'           " pairs of '[' and ']' mappings

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
let g:airline_theme = 'gruvbox'
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
" CONQUER OF COMPLETION
" ------------------------------------------------------------------------

" Coc plugins to automatically install and update in any project
let g:coc_global_extensions = [
  \ 'coc-css',
  \ 'coc-explorer',
  \ 'coc-fzf-preview',
  \ 'coc-highlight',
  \ 'coc-html',
  \ 'coc-json',
  \ 'coc-snippets',
  \ 'coc-vimlsp',
  \ 'coc-yaml',
  \ 'coc-yank'
  \ ]

if isdirectory('./node_modules')
  " Activate import cost
  let g:coc_global_extensions += ['coc-import-cost']

  " Activate prettier (if installed)
  if isdirectory('./node_modules/prettier')
    let g:coc_global_extensions += ['coc-prettier']
  endif

  " Activate eslint (if installed)
  if isdirectory('./node_modules/eslint')
    let g:coc_global_extensions += ['coc-eslint']
  endif

  " Activate flow or typescript (if installed), but never both
  if isdirectory('./node_modules/flow-bin')
    let g:coc_global_extensions += ['coc-flow']
  elseif isdirectory('./node_modules/typescript')
    let g:coc_global_extensions += ['coc-tsserver']
  endif

  " Activate inline jest (if jest installed)
  if isdirectory('./node_modules/jest')
    let g:coc_global_extensions += ['coc-inline-jest']
  endif

  " Activate tailwind (if installed)
  if isdirectory('./node_modules/tailwindcss')
    let g:coc_global_extensions += ['coc-tailwindcss']
  endif
endif

if isdirectory('./git')
  let g:coc_global_extensions += ['coc-git']
endif

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR :call CocAction('runCommand', 'editor.action.organizeImport')

" ------------------------------------------------------------------------
" COC GIT
" ------------------------------------------------------------------------

let b:coc_git_blame = 1  " git status of current line
let b:coc_git_status = 1 " git status of current buffer

" ------------------------------------------------------------------------
" FZF
" ------------------------------------------------------------------------

" https://github.com/junegunn/fzf#search-syntax
if executable('rg')
  let g:rg_derive_root='true'
endif
set grepprg=rg\ --vimgrep\ --smart-case\ --hidden\ --follow

" Floating window
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.9 } }
let $FZF_DEFAULT_OPTS='--reverse'

" Close search window with Esc
" https://github.com/junegunn/fzf/issues/1393#issuecomment-426576577
autocmd! FileType fzf tnoremap <buffer> <esc> <c-c>

" ------------------------------------------------------------------------
" NETRW
" ------------------------------------------------------------------------

" " Disable Netrw file tree
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

" Prevent coc-explorer from staying stuck in the last session's CWD after :SClose
autocmd User Startified :silent CocRestart

" Create viminfo file (for new installs)
" https://github.com/ChristianChiarulli/nvim/issues/5#issuecomment-625933872
" set viminfo='100,n$HOME/.config/nvim/autoload/plugged/vim-startify/test/viminfo'

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
" VIM POLYGLOT
" ------------------------------------------------------------------------

let g:polyglot_disabled = ['javascript', 'jsx', 'typescript']

" ------------------------------------------------------------------------
" VIM TEST
" ------------------------------------------------------------------------

let test#strategy = 'neovim'
let test#neovim#term_position = "vert"

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
