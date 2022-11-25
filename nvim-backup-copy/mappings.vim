" NOTE: add most <Leader> mappings to Which Key menu (at the end of this file)

let mapleader = " "

" ------------------------------------------------------------------------
" NORMAL + VISUAL MODE
" ------------------------------------------------------------------------

" -----------------------
" Workman keyboard layout
" -----------------------

" " h <-> y
" noremap y h
" noremap Y H
" noremap h y
" noremap H y$ " Make Y behave like D and C by yanking remainder of line only
" onoremap h y

" " j <-> n
" noremap n j
" noremap N J
" noremap j n
" noremap J N
" noremap gn gj
" noremap gj gn

" " k <-> e
" noremap e k
" noremap E <nop>
" noremap k e
" noremap K E
" noremap ge gk
" noremap gk ge

" " l <-> o
" noremap o l
" noremap O L
" noremap l o
" noremap L O

" Easily exit help windows with Esc or q
autocmd Filetype help nmap <buffer> <Esc> :q<CR>
autocmd Filetype help nmap <buffer> q :q<CR>

" function! s:show_documentation()
"   if (index(['vim','help'], &filetype) >= 0)
"     execute 'h '.expand('<cword>')
"   else
"     exec ":lua vim.lsp.buf.hover()"
"   endif
" endfunction

" " Get details on hover
" noremap ga :Telescope lsp_code_actions<CR>
" noremap gh :call <SID>show_documentation()<CR>
" noremap gs :lua vim.lsp.buf.signature_help()<CR>

" " Go to related code
" noremap gd :lua vim.lsp.buf.definition()<CR>
" noremap gi :lua vim.lsp.buf.implementation()<CR>
" noremap gm :Telescope marks<CR>

" ------------------------------------------------------------------------
" NORMAL MODE ONLY
" ------------------------------------------------------------------------

" Navigate between buffers
nnoremap <TAB>   :bnext<CR>
nnoremap <S-TAB> :bprevious<CR>

" ------------------------------------------------------------------------
" INSERT MODE ONLY
" ------------------------------------------------------------------------

" " Better nav for omnicomplete
" inoremap <expr> <c-n> ("\<C-n>")
" inoremap <expr> <c-e> ("\<C-p>")

" " Accept suggestion with Enter
" if exists('*complete_info')
"   inoremap <expr> <CR> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
" else
"   inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" endif

" ------------------------------------------------------------------------
" TERMINAL MODE
" ------------------------------------------------------------------------

" Return to normal mode
tnoremap <Esc> <C-\><C-n>

" ------------------------------------------------------------------------
" WHICH KEY (leader key mappings)
" ------------------------------------------------------------------------

" Need at least one <Leader> mapping outside menu for Which Key menu delay to work
nnoremap <Leader>[ :vertical resize -5<CR>
nnoremap <Leader>] :vertical resize +5<CR>

" Initialize key map
let g:which_key_map =  {}

let g:which_key_map['='] = ['<C-w>='                                       , 'equal width windows']
let g:which_key_map['b'] = [':Telescope buffers'                           , 'buffer search']
let g:which_key_map['c'] = [':Telescope command_history'                   , 'command history' ]
let g:which_key_map['d'] = [':Bdelete menu'                                , 'delete buffers']
let g:which_key_map['e'] = [':exec "lua vim.lsp.diagnostic.set_loclist()"' , 'error list']

let g:which_key_map['f'] = {
  \ 'name' : '+find',
  \ 'f' : [':Telescope find_files', 'files'],
  \ 'g' : [':Telescope git_files', 'git files'],
  \ 'p' : [':Telescope live_grep', 'phrase'],
  \ 'r' : [':Telescope lsp_references', 'references'],
  \ 'R' : [':Telescope registers', 'registers'],
  \ 's' : [':Telescope lsp_document_symbols', 'symbols'],
  \ }

nnoremap <leader>vrn :lua vim.lsp.buf.rename()<CR>
nnoremap <leader>vsd :lua vim.lsp.diagnostic.show_line_diagnostics()<CR>

let g:which_key_map['g'] = {
  \ 'name' : '+git' ,
  \ 'A' : [':Git add .'              , 'add all'],
  \ 'b' : [':Telescope git_branches' , 'branches (local + remote)'],
  \ 'B' : [':Git blame'              , 'blame'],
  \ 'c' : [':Telescope git_bcommits' , 'commits (buffer)'],
  \ 'C' : [':Telescope git_commits'  , 'commits (repo)'],
  \ 'd' : [':vert Gdiff'             , 'diff'],
  \ 'g' : [':GGrep'                  , 'git grep'],
  \ 'm' : [':Git move'               , 'move'],
  \ 'p' : [':Git push --no-verify'   , 'push (no verify)'],
  \ 'P' : [':Git pull --ff'          , 'pull (ff when possible)'],
  \ 'r' : [':GRemove'                , 'remove'],
  \ 's' : [':vert Git'               , 'status (in split)'],
  \ 'S' : [':tab Git'                , 'status (in tab)'],
  \ }

let g:which_key_map['h'] = [':let @/ = ""' , 'highlights off']

" let g:which_key_map['i'] = ['' , '' ]
" let g:which_key_map['j'] = ['' , '' ]

let g:which_key_map['k'] = [':Telescope keymaps'                                   , 'keymaps' ]
let g:which_key_map['l'] = [":normal \"ahiwlconsole.log('\<C-R>a:', \<C-R>a)\<CR>" , 'log to console']

" let g:which_key_map['m'] = ['', '' ]
" let g:which_key_map['n'] = ['', '']

let g:which_key_map['o'] = [':Vifm', 'open file tree']

" let g:which_key_map['p'] = ['', 'snippets']

let g:which_key_map['q'] = [':q'                              , 'quit window']
let g:which_key_map['r'] = [':source ~/.config/nvim/init.vim' , 'reload neovim']

let g:which_key_map['s'] = {
  \ 'name' : '+session',
  \ 'd' : [':SDelete' , 'delete'],
  \ 's' : [':SSave'   , 'save'],
  \ 'x' : [':SClose'  , 'exit'],
  \}

" Vim Test
" let g:which_key_map['t'] = {
"   \ 'name' : '+test' ,
"   \ 'f' : [':TestFile'    , 'file's tests (or last run file's tests)'],
"   \ 'l' : [':TestLast'    , 'last test'],
"   \ 'n' : [':TestNearest' , 'nearest test to cursor'],
"   \ 's' : [':TestSuite'   , 'suite of tests'],
"   \ 'v' : [':TestVisit'   , 'visit file with last run tests'],
"   \}

let g:which_key_map['u'] = [':UndotreeShow'                         , 'undo list']
let g:which_key_map['v'] = ['<C-w>v'                                , 'vertical split']
let g:which_key_map['w'] = [':write | edit | TSBufEnable highlight' , 'write buffer']

" let g:which_key_map['x'] = ['', '']
" let g:which_key_map['y'] = ['', 'yank list']
" let g:which_key_map['z'] = ['', '']

" Register which key map
call which_key#register('<Space>', 'g:which_key_map')

" Map leader to which_key
nnoremap <silent> <leader> :silent <c-u> :silent WhichKey '<Space>'<CR>
vnoremap <silent> <leader> :silent <c-u> :silent WhichKeyVisual '<Space>'<CR>
