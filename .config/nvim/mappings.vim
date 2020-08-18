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

" Move vertically through each virtual wrapped line
nmap j gj
nmap k gk

" Window actions
noremap <C-h> <C-w>h
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l

" Keep cursor near the middle of the screen
autocmd InsertEnter * norm zz

" Easily exit temporary windows with Esc or q
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
" VISUAL MODE ONLY
" ------------------------------------------------------------------------

" Return to normal mode
noremap! jk <Esc>
noremap! kj <Esc>

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
inoremap jk    <Esc>:w<CR>
inoremap kj    <Esc>:w<CR>

" ------------------------------------------------------------------------
" TERMINAL MODE
" ------------------------------------------------------------------------

" Return to normal mode
tnoremap jk    <C-\><C-n>
tnoremap kj    <C-\><C-n>
tnoremap <Esc> <C-\><C-n>

" Navigate panes
tnoremap <Leader>h <C-\><C-n><C-w>h
tnoremap <Leader>j <C-\><C-n><C-w>j
tnoremap <Leader>k <C-\><C-n><C-w>k
tnoremap <Leader>l <C-\><C-n><C-w>l

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

let g:which_key_map[';'] = [ ':CocList commands'               , 'commands' ]
let g:which_key_map['='] = [ '<C-w>='                          , 'equal width windows' ]
let g:which_key_map['a'] = [ '<Plug>(coc-codeaction)'          , 'actions' ]
let g:which_key_map['b'] = [ ':CocCommand fzf-preview.Buffers' , 'buffers' ]

" Conquer of Completion
let g:which_key_map['c'] = {
  \ 'name' : '+coc' ,
  \ '.' : [':CocConfig'                        , 'config'],
  \ ';' : ['<Plug>(coc-refactor)'              , 'refactor'],
  \ 'a' : ['<Plug>(coc-codeaction)'            , 'line action'],
  \ 'A' : ['<Plug>(coc-codeaction-selected)'   , 'selected action'],
  \ 'b' : [':CocNext'                          , 'next action'],
  \ 'B' : [':CocPrev'                          , 'prev action'],
  \ 'c' : [':CocList commands'                 , 'commands'],
  \ 'd' : ['<Plug>(coc-definition)'            , 'definition'],
  \ 'D' : ['<Plug>(coc-declaration)'           , 'declaration'],
  \ 'e' : [':CocList extensions'               , 'extensions'],
  \ 'f' : ['<Plug>(coc-format-selected)'       , 'format selected'],
  \ 'F' : ['<Plug>(coc-format)'                , 'format'],
  \ 'h' : ['<Plug>(coc-float-hide)'            , 'hide'],
  \ 'i' : ['<Plug>(coc-implementation)'        , 'implementation'],
  \ 'I' : [':CocList diagnostics'              , 'diagnostics'],
  \ 'j' : ['<Plug>(coc-float-jump)'            , 'float jump'],
  \ 'l' : ['<Plug>(coc-codelens-action)'       , 'code lens'],
  \ 'n' : ['<Plug>(coc-diagnostic-next)'       , 'next diagnostic'],
  \ 'N' : ['<Plug>(coc-diagnostic-next-error)' , 'next error'],
  \ 'o' : ['<Plug>(coc-openlink)'              , 'open link'],
  \ 'O' : [':CocList outline'                  , 'outline'],
  \ 'p' : ['<Plug>(coc-diagnostic-prev)'       , 'prev diagnostic'],
  \ 'P' : ['<Plug>(coc-diagnostic-prev-error)' , 'prev error'],
  \ 'q' : ['<Plug>(coc-fix-current)'           , 'quickfix'],
  \ 'r' : ['<Plug>(coc-rename)'                , 'rename'],
  \ 'R' : ['<Plug>(coc-references)'            , 'references'],
  \ 's' : [':CocList -I symbols'               , 'references'],
  \ 'S' : [':CocList snippets'                 , 'snippets'],
  \ 't' : ['<Plug>(coc-type-definition)'       , 'type definition'],
  \ 'u' : [':CocListResume'                    , 'resume list'],
  \ 'U' : [':CocUpdate'                        , 'update CoC'],
  \ 'v' : [':Vista!!'                          , 'tag viewer'],
  \ 'z' : [':CocDisable'                       , 'disable CoC'],
  \ 'Z' : [':CocEnable'                        , 'enable CoC'],
  \ }

let g:which_key_map['d'] = [ ':bd'                                    , 'delete buffer']
let g:which_key_map['e'] = [ ':CocCommand fzf-preview.CocDiagnostics' , 'errors' ]
let g:which_key_map['f'] = [ ':CocCommand fzf-preview.GitFiles'       , 'files' ]

" Git
let g:which_key_map['g'] = {
  \ 'name' : '+git' ,
  \ 'a' : [':Git add %'                      , 'add current file'],
  \ 'A' : [':Git add .'                      , 'add all files'],
  \ 'b' : [':Git blame'                      , 'blame'],
  \ 'B' : [':CocCommand fzf-preview.BlamePR' , 'blame PR'],
  \ 'c' : [':Git commit'                     , 'commit'],
  \ 'd' : [':Git diff'                       , 'diff'],
  \ 'D' : [':Gdiffsplit'                     , 'diff split'],
  \ 'g' : [':GGrep'                          , 'git grep'],
  \ 'l' : [':Git log'                        , 'log'],
  \ 'm' : [':Git move'                       , 'move'],
  \ 'p' : [':Git push'                       , 'push'],
  \ 'P' : [':Git pull'                       , 'pull'],
  \ 'r' : [':GRemove'                        , 'remove'],
  \ 's' : [':vert Git'                       , 'status in split'],
  \ 'S' : [':tab Git'                        , 'status in tab'],
  \ }

let g:which_key_map['h'] = [ '<C-w>h'                                     , 'left a window' ]
let g:which_key_map['i'] = [ ':Codi'                                      , 'inline evaluation on' ]
let g:which_key_map['I'] = [ ':Codi!'                                     , 'inline evaluation off' ]
let g:which_key_map['j'] = [ '<C-w>j'                                     , 'down a window' ]
let g:which_key_map['k'] = [ '<C-w>k'                                     , 'up a window' ]
let g:which_key_map['l'] = [ '<C-w>l'                                     , 'right a window' ]
let g:which_key_map['L'] = [ "\"ayiwoconsole.log('<C-R>a:', <C-R>a)<Esc>" , 'log to console' ]

" let g:which_key_map['m'] = [ ':EditVifm'                 , 'manage files' ]

let g:which_key_map['n'] = [ ':let @/ = ""'       , 'no search highlights' ]
let g:which_key_map['o'] = [ ':Vexplore'          , 'open file tree' ]
let g:which_key_map['q'] = [ ':q'                 , 'quit window (or session if last window)' ]
let g:which_key_map['r'] = [ '<Plug>(coc-rename)' , 'rename symbol' ]

let @g = ':CocCommand fzf-preview.ProjectGrep '
let @s = ':CocSearch '

" Rename the word under the cursor across the project ("project rename word")
nnoremap <Leader>prw :CocSearch <C-R>=expand("<cword>")<CR><CR>

" FZF Preview
let g:which_key_map['s'] = {
  \ 'name' : '+search' ,
  \ 'b' : [':CocCommand fzf-preview.Buffers'        , 'buffers'],
  \ 'c' : [':CocCommand fzf-preview.Changes'        , 'changes'],
  \ 'd' : [':CocCommand fzf-preview.DirectoryFiles' , 'files in directory'],
  \ 'f' : [':CocCommand fzf-preview.ProjectFiles'   , 'files in project'],
  \ 'g' : [':CocCommand fzf-preview.GitFiles'       , 'files in git'],
  \ 'j' : [':CocCommand fzf-preview.Jumps'          , 'jumps'],
  \ 'l' : [':CocCommand fzf-preview.Lines'          , 'lines in buffer'],
  \ 'm' : [':CocCommand fzf-preview.Marks'          , 'marks'] ,
  \ 'p' : [':CocList snippets'                      , 'snippets'],
  \ 'q' : [':CocCommand fzf-preview.QuickFix'       , 'quick fix list'],
  \ 't' : [':CocCommand fzf-preview.BufferTags'     , 'tags from all buffers'],
  \ 'r' : ['@g'                                     , 'grep project words'],
  \ 's' : ['@s'                                     , 'search project words'],
  \ }

let g:which_key_map['t'] = [ ':tab split'                , 'open buffer in new tab' ]
let g:which_key_map['u'] = [ ':UndotreeShow'             , 'undo tree' ]
let g:which_key_map['v'] = [ '<C-w>v'                    , 'vertically split']
let g:which_key_map['w'] = [ ':w'                        , 'write buffer to file' ]
let g:which_key_map['x'] = [ ':SClose'                   , 'close session' ]
let g:which_key_map['y'] = [ ':CocCommand fzf-preview.Yankround' , 'yank history' ]

" Register which key map
call which_key#register('<Space>', 'g:which_key_map')

" Map leader to which_key
nnoremap <silent> <leader> :silent <c-u> :silent WhichKey '<Space>'<CR>
vnoremap <silent> <leader> :silent <c-u> :silent WhichKeyVisual '<Space>'<CR>
