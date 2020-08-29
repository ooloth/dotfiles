" NOTE: add most <Leader> mappings to Which Key menu (at the end of this file)

let mapleader = " "

" ------------------------------------------------------------------------
" NORMAL + VISUAL MODE
" ------------------------------------------------------------------------

"Disable arrow key navigation
noremap <Up> <nop>
noremap <Right> <nop>
noremap <Down> <nop>
noremap <Left> <nop>

" Find a character in the visible part of the window
map f <Plug>(easymotion-s)

" Jump to one of the visible words
map ff <Plug>(easymotion-bd-w)

map  <Leader>/ <Plug>(easymotion-sn)
omap <Leader>/ <Plug>(easymotion-tn)
" map n <Plug>(easymotion-next)
" map N <Plug>(easymotion-prev)

" Easily exit help windows with Esc or q
autocmd Filetype help nmap <buffer> <Esc> :q<CR>
autocmd Filetype help nmap <buffer> q :q<CR>

" ------------------------------------------------------------------------
" NORMAL MODE ONLY
" ------------------------------------------------------------------------

" Navigate between buffers
nnoremap <TAB>   :bnext<CR>
nnoremap <S-TAB> :bprevious<CR>

" Make Y behave like D and C by yank remainder of line instead of entire line
nnoremap Y y$

" ------------------------------------------------------------------------
" INSERT MODE ONLY
" ------------------------------------------------------------------------

" Turn off arrow keys
inoremap <Up> <nop>
inoremap <Right> <nop>
inoremap <Down> <nop>
inoremap <Left> <nop>

" Return to normal mode + autosave
inoremap <Esc> <Esc>:w<CR>

" ------------------------------------------------------------------------
" TERMINAL MODE
" ------------------------------------------------------------------------

" Return to normal mode
tnoremap <Esc> <C-\><C-n>

" ------------------------------------------------------------------------
" CONQUER OF COMPLETION
" ------------------------------------------------------------------------

" Source: https://github.com/neoclide/coc.nvim#example-vim-configuration

" Use tab for trigger completion with characters ahead and navigate.
inoremap <silent><expr> <TAB>
  \ pumvisible() ? "\<C-n>" :
  \ <SID>check_back_space() ? "\<TAB>" :
  \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Better nav for omnicomplete
inoremap <expr> <c-j> ("\<C-n>")
inoremap <expr> <c-k> ("\<C-p>")

" Accept suggestion with Enter
if exists('*complete_info')
  inoremap <expr> <CR> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

" ------------------------------------------------------------------------
" WHICH KEY (leader key mappings)
" ------------------------------------------------------------------------

" Need at least one <Leader> mapping outside menu for Which Key menu delay to work
nnoremap <Leader>[ :vertical resize -5<CR>
nnoremap <Leader>] :vertical resize +5<CR>

" Initialize key map
let g:which_key_map =  {}

let g:which_key_map[';'] = [':CocList commands'                      , 'commands']
let g:which_key_map['='] = ['<C-w>='                                 , 'equal width windows']
let g:which_key_map['a'] = ['<Plug>(coc-codeaction)'                 , 'actions']
let g:which_key_map['b'] = [':CocCommand fzf-preview.Buffers'        , 'buffers']
let g:which_key_map['c'] = [':SClose'                                , 'close session']
let g:which_key_map['d'] = [':Bdelete menu'                          , 'delete buffers']
let g:which_key_map['e'] = [':CocCommand fzf-preview.CocDiagnostics' , 'errors']
let g:which_key_map['f'] = [':CocCommand fzf-preview.ProjectFiles'   , 'files']

" Git
let g:which_key_map['g'] = {
  \ 'name' : '+git' ,
  \ 'a' : [':CocCommand fzf-preview.GitActions'  , 'actions'],
  \ 'A' : [':Git add .'                          , 'add all'],
  \ 'b' : [':CocCommand fzf-preview.GitBranches' , 'branches'],
  \ 'B' : [':Git blame'                          , 'blame'],
  \ 'c' : [':Git commit'                         , 'commit'],
  \ 'd' : [':vert Gdiff'                         , 'diff'],
  \ 'g' : [':GGrep'                              , 'git grep'],
  \ 'h' : [':CocCommand fzf-preview.GitStashes'  , 'stashes'],
  \ 'l' : [':CocCommand fzf-preview.GitLogs'     , 'log'],
  \ 'm' : [':Git move'                           , 'move'],
  \ 'p' : [':Git push --no-verify'               , 'push (no verify)'],
  \ 'P' : [':Git pull --ff'                      , 'pull (ff when possible)'],
  \ 'r' : [':GRemove'                            , 'remove'],
  \ 's' : [':vert Git'                           , 'status in split'],
  \ 'S' : [':tab Git'                            , 'status in tab'],
  \ }

let g:which_key_map['h'] = [':let @/ = ""' , 'hide highlights']

" let g:which_key_map['i'] = [ '' , '' ]

let g:which_key_map['j'] = [ '<Plug>(easymotion-j)' , 'jump down to a line' ]
let g:which_key_map['k'] = [ '<Plug>(easymotion-k)' , 'jump up to a line' ]

nnoremap <Leader>l "ayiwoconsole.log('<C-R>a:', <C-R>a)<Esc>
let g:which_key_map['l'] = ['l' , 'log to console' ]

" let g:which_key_map['m'] = [ '' , '' ]

let g:which_key_map['n'] = ['<Plug>(coc-references)' , 'references']
let g:which_key_map['o'] = [':CocCommand explorer'   , 'open file tree']
let g:which_key_map['p'] = [':CocList snippets'      , 'snippets']
let g:which_key_map['q'] = [':q'                     , 'quit window (or session if last window)']

let @r = ':CocCommand fzf-preview.ProjectGrep '
let g:which_key_map['r'] = ['@r' , 'ripgrep word']

let @s = ':CocSearch '
let g:which_key_map['s'] = ['@s' , 'search word']

" Vim Test
let g:which_key_map['t'] = {
  \ 'name' : '+test' ,
  \ 'f' : [':TestFile'    , "file's tests (or last run file's tests)"],
  \ 'l' : [':TestLast'    , 'last test'],
  \ 'n' : [':TestNearest' , 'nearest test to cursor'],
  \ 's' : [':TestSuite'   , 'suite of tests'],
  \ 'v' : [':TestVisit'   , 'visit file with last run tests'],
  \}

let g:which_key_map['u'] = [':UndotreeShow' , 'undo tree']
let g:which_key_map['v'] = ['<C-w>v'        , 'vertical split']
let g:which_key_map['w'] = [':w'            , 'write buffer']

" let g:which_key_map['x'] = [ '' , '' ]

let g:which_key_map['y'] = [ ':CocList -A --normal yank' , 'yanks' ]

" let g:which_key_map['z'] = [ '' , '' ]

" Register which key map
call which_key#register('<Space>', 'g:which_key_map')

" Map leader to which_key
nnoremap <silent> <leader> :silent <c-u> :silent WhichKey '<Space>'<CR>
vnoremap <silent> <leader> :silent <c-u> :silent WhichKeyVisual '<Space>'<CR>
