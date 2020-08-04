let mapleader = " "

" ------------------------------------------------------------------------
" NORMAL + VISUAL MODE
" ------------------------------------------------------------------------

"Disable arrow key navigation
noremap <Up> <nop>
noremap <Right> <nop>
noremap <Down> <nop>
noremap <Left> <nop>

" Close the current buffer (use ZZ for :wq)
noremap <Leader>w :w<CR>
noremap <Leader>q :q<CR>

"Show file explorer
noremap <Leader>e :CocCommand explorer<CR>

" Search current file with 'f'
noremap f /
noremap F ?

" Keep cursor near the middle of the screen
noremap n nzz
noremap N Nzz
noremap } }zz
noremap { {zz
noremap G Gzz
noremap i zzi
noremap I zzI
noremap a zza
noremap A zzA
noremap s zzs
noremap S zzS

" Search all file names with fzf (mapped to 'ff'; like Cmd-P in VS Code)
noremap ff :Files<CR>

" Grep all file contents with fzf and ripgrep (like Cmd-Shift-f in VS Code)
noremap <Leader>g :Rg<Space>

" Navigate window panes
noremap <Leader>h <C-w>h
noremap <Leader>j <C-w>j
noremap <Leader>k <C-w>k
noremap <Leader>l <C-w>l
" noremap <C-h> <C-w>h
" noremap <C-j> <C-w>j
" noremap <C-k> <C-w>k
" noremap <C-l> <C-w>l

" View buffer list
noremap <Leader>b :Buffers<Cr>

"View documentation pop-up for word under cursor
noremap <silent> K :call CocAction('doHover')<CR>

"Go to related details about word under cursor
noremap <silent> gd <Plug>(coc-definition)
noremap <silent> gy <Plug>(coc-type-definition)
noremap <silent> gr <Plug>(coc-references)

"Go to prev/next error in current file
noremap <silent> [g <Plug>(coc-diagnostic-prev)
noremap <silent> ]g <Plug>(coc-diagnostic-next)

"See all workspace errors and warnings
noremap <silent> <space>d :<C-u>CocList diagnostics<cr>

"See all symbols in workspace
noremap <silent> <space>s :<C-u>CocList -I symbols<cr>

"Rename symbol under cursor
noremap <leader>rn <Plug>(coc-rename)

"Prompt for how to autofix issue with word under cursor
noremap <leader>do <Plug>(coc-codeaction)

" Toggle comments
noremap <Leader>c :Commentary<cr>
noremap <Leader>/ :Commentary<cr>

" Wrap word under cursor in a console log
" https://vi.stackexchange.com/a/21896
noremap <Leader>L "ayiwoconsole.log('<C-R>a:', <C-R>a);<Esc>

" Show undo tree
noremap <Leader>u :UndotreeShow<CR>

" Open current file in new tab (to temporarily work on it fullscreen)
" https://stackoverflow.com/a/15584901
noremap tt :tab split<CR>

" ------------------------------------------------------------------------
" NORMAL MODE ONLY
" ------------------------------------------------------------------------

" Navigate between buffers
nnoremap <TAB>   :bnext<CR>
nnoremap <S-TAB> :bprevious<CR>

" Make Y behave like D and C by yank remainder of line instead of entire line
nnoremap Y y$

" Open yank list
nnoremap <silent> <space>y  :<C-u>CocList -A --normal yank<cr>

" ------------------------------------------------------------------------
" VISUAL MODE ONLY
" ------------------------------------------------------------------------

" Return to normal mode
vnoremap ;; <Esc>
vnoremap ii <Esc>

" ------------------------------------------------------------------------
" INSERT + COMMAND LINE MODE
" ------------------------------------------------------------------------

" Return to normal mode (use Ctrl-c when these aren't available)
noremap! ;; <Esc>
noremap! ii <Esc>

" ------------------------------------------------------------------------
" INSERT MODE ONLY
" ------------------------------------------------------------------------

" Turn off arrow keys
inoremap <Up> <nop>
inoremap <Right> <nop>
inoremap <Down> <nop>
inoremap <Left> <nop>

" Use tab for trigger completion with characters ahead and navigate.
inoremap <silent><expr> <TAB>
  \ pumvisible() ? "\<C-n>" :
  \ <SID>check_back_space() ? "\<TAB>" :
  \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Better nav for omnicomplete
inoremap <expr> <c-j> ("\<C-n>")
inoremap <expr> <c-k> ("\<C-p>")

" ------------------------------------------------------------------------
" TERMINAL MODE
" ------------------------------------------------------------------------

" Return to normal mode
tnoremap ;;    <C-\><C-n>
tnoremap ii    <C-\><C-n>
tnoremap <Esc> <C-\><C-n>

" Navigate panes
tnoremap <Leader>h <C-\><C-n><C-w>h
tnoremap <Leader>j <C-\><C-n><C-w>j
tnoremap <Leader>k <C-\><C-n><C-w>k
tnoremap <Leader>l <C-\><C-n><C-w>l

" ------------------------------------------------------------------------
" FLOATERM
" ------------------------------------------------------------------------

let g:floaterm_keymap_toggle = '<F1>'
let g:floaterm_keymap_next   = '<F2>'
let g:floaterm_keymap_prev   = '<F3>'
let g:floaterm_keymap_new    = '<F4>'

" ------------------------------------------------------------------------
" Which Key
" ------------------------------------------------------------------------

" Map leader to which_key
nnoremap <silent> <leader> :silent <c-u> :silent WhichKey '<Space>'<CR>
vnoremap <silent> <leader> :silent <c-u> :silent WhichKeyVisual '<Space>'<CR>

" " Create map to add keys to
let g:which_key_map =  {}

" Todo get these plugins working...
" let g:which_key_map['t'] = {
"   \ 'name' : '+terminal' ,
"   \ ';' : [':FloatermNew --wintype=popup --height=6', 'terminal'],
"   \ 'f' : [':FloatermNew fzf'                       , 'fzf'],
"   \ 'g' : [':FloatermNew lazygit'                   , 'git'],
"   \ 'n' : [':FloatermNew node'                      , 'node'],
"   \ 'r' : [':FloatermNew ranger'                    , 'ranger'],
"   \ 't' : [':FloatermToggle'                        , 'toggle'],
"   \ }

" Register which key map
call which_key#register('<Space>', "g:which_key_map")

" " Single mappings
" let g:which_key_map['/'] = [ ':call Comment()'            , 'comment' ]
" let g:which_key_map['.'] = [ ':e $MYVIMRC'                , 'open init' ]
" let g:which_key_map[';'] = [ ':Commands'                  , 'commands' ]
" let g:which_key_map['='] = [ '<C-W>='                     , 'balance windows' ]
" let g:which_key_map[','] = [ 'Startify'                   , 'start screen' ]
" let g:which_key_map['d'] = [ ':bd'                        , 'delete buffer']
" let g:which_key_map['e'] = [ ':CocCommand explorer'       , 'explorer' ]
" let g:which_key_map['f'] = [ ':Files'                     , 'search files' ]
" let g:which_key_map['h'] = [ '<C-W>s'                     , 'split below']
" let g:which_key_map['q'] = [ 'q'                          , 'quit' ]
" let g:which_key_map['r'] = [ ':RnvimrToggle'              , 'ranger' ]
" let g:which_key_map['S'] = [ ':SSave'                     , 'save session' ]
" let g:which_key_map['T'] = [ ':Rg'                        , 'search text' ]
" let g:which_key_map['v'] = [ '<C-W>v'                     , 'split right']
" let g:which_key_map['W'] = [ 'w'                          , 'write' ]
" let g:which_key_map['z'] = [ 'Goyo'                       , 'zen' ]

" " Group mappings

" " a is for actions
" let g:which_key_map.a = {
"       \ 'name' : '+actions' ,
"       \ 'c' : [':ColorizerToggle'        , 'colorizer'],
"       \ 'e' : [':CocCommand explorer'    , 'explorer'],
"       \ 'n' : [':set nonumber!'          , 'line-numbers'],
"       \ 'r' : [':set norelativenumber!'  , 'relative line nums'],
"       \ 's' : [':let @/ = ""'            , 'remove search highlight'],
"       \ 't' : [':FloatermToggle'         , 'terminal'],
"       \ 'v' : [':Codi'                   , 'virtual repl on'],
"       \ 'V' : [':Codi!'                  , 'virtual repl off'],
"       \ }

" " b is for buffer
" let g:which_key_map.b = {
"       \ 'name' : '+buffer' ,
"       \ '1' : ['b1'        , 'buffer 1']        ,
"       \ '2' : ['b2'        , 'buffer 2']        ,
"       \ 'd' : ['bd'        , 'delete-buffer']   ,
"       \ 'f' : ['bfirst'    , 'first-buffer']    ,
"       \ 'h' : ['Startify'  , 'home-buffer']     ,
"       \ 'l' : ['blast'     , 'last-buffer']     ,
"       \ 'n' : ['bnext'     , 'next-buffer']     ,
"       \ 'p' : ['bprevious' , 'previous-buffer'] ,
"       \ '?' : ['Buffers'   , 'fzf-buffer']      ,
"       \ }

" " s is for search
" let g:which_key_map.s = {
"       \ 'name' : '+search' ,
"       \ '/' : [':History/'              , 'history'],
"       \ ';' : [':Commands'              , 'commands'],
"       \ 'a' : [':Ag'                    , 'text Ag'],
"       \ 'b' : [':BLines'                , 'current buffer'],
"       \ 'B' : [':Buffers'               , 'open buffers'],
"       \ 'c' : [':Commits'               , 'commits'],
"       \ 'C' : [':BCommits'              , 'buffer commits'],
"       \ 'f' : [':Files'                 , 'files'],
"       \ 'g' : [':GFiles'                , 'git files'],
"       \ 'G' : [':GFiles?'               , 'modified git files'],
"       \ 'h' : [':History'               , 'file history'],
"       \ 'H' : [':History:'              , 'command history'],
"       \ 'l' : [':Lines'                 , 'lines'] ,
"       \ 'm' : [':Marks'                 , 'marks'] ,
"       \ 'M' : [':Maps'                  , 'normal maps'] ,
"       \ 'p' : [':Helptags'              , 'help tags'] ,
"       \ 'P' : [':Tags'                  , 'project tags'],
"       \ 's' : [':CocList snippets'      , 'snippets'],
"       \ 'S' : [':Colors'                , 'color schemes'],
"       \ 't' : [':Rg'                    , 'text Rg'],
"       \ 'T' : [':BTags'                 , 'buffer tags'],
"       \ 'w' : [':Windows'               , 'search windows'],
"       \ 'y' : [':Filetypes'             , 'file types'],
"       \ 'z' : [':FZF'                   , 'FZF'],
"       \ }
"       " \ 's' : [':Snippets'     , 'snippets'],

" " g is for git
" let g:which_key_map.g = {
"       \ 'name' : '+git' ,
"       \ 'a' : [':Git add .'                        , 'add all'],
"       \ 'A' : [':Git add %'                        , 'add current'],
"       \ 'b' : [':Git blame'                        , 'blame'],
"       \ 'B' : [':GBrowse'                          , 'browse'],
"       \ 'c' : [':Git commit'                       , 'commit'],
"       \ 'd' : [':Git diff'                         , 'diff'],
"       \ 'D' : [':Gdiffsplit'                       , 'diff split'],
"       \ 'g' : [':GGrep'                            , 'git grep'],
"       \ 'G' : [':Gstatus'                          , 'status'],
"       \ 'h' : [':GitGutterLineHighlightsToggle'    , 'highlight hunks'],
"       \ 'H' : ['<Plug>(GitGutterPreviewHunk)'      , 'preview hunk'],
"       \ 'j' : ['<Plug>(GitGutterNextHunk)'         , 'next hunk'],
"       \ 'k' : ['<Plug>(GitGutterPrevHunk)'         , 'prev hunk'],
"       \ 'l' : [':Git log'                          , 'log'],
"       \ 'p' : [':Git push'                         , 'push'],
"       \ 'P' : [':Git pull'                         , 'pull'],
"       \ 'r' : [':GRemove'                          , 'remove'],
"       \ 's' : ['<Plug>(GitGutterStageHunk)'        , 'stage hunk'],
"       \ 'S' : [':!git status'                       , 'status'],
"       \ 't' : [':GitGutterSignsToggle'             , 'toggle signs'],
"       \ 'u' : ['<Plug>(GitGutterUndoHunk)'         , 'undo hunk'],
"       \ 'v' : [':GV'                               , 'view commits'],
"       \ 'V' : [':GV!'                              , 'view buffer commits'],
"       \ }

" " l is for language server protocol
" let g:which_key_map.l = {
"       \ 'name' : '+lsp' ,
"       \ '.' : [':CocConfig'                          , 'config'],
"       \ ';' : ['<Plug>(coc-refactor)'                , 'refactor'],
"       \ 'a' : ['<Plug>(coc-codeaction)'              , 'line action'],
"       \ 'A' : ['<Plug>(coc-codeaction-selected)'     , 'selected action'],
"       \ 'b' : [':CocNext'                            , 'next action'],
"       \ 'B' : [':CocPrev'                            , 'prev action'],
"       \ 'c' : [':CocList commands'                   , 'commands'],
"       \ 'd' : ['<Plug>(coc-definition)'              , 'definition'],
"       \ 'D' : ['<Plug>(coc-declaration)'             , 'declaration'],
"       \ 'e' : [':CocList extensions'                 , 'extensions'],
"       \ 'f' : ['<Plug>(coc-format-selected)'         , 'format selected'],
"       \ 'F' : ['<Plug>(coc-format)'                  , 'format'],
"       \ 'h' : ['<Plug>(coc-float-hide)'              , 'hide'],
"       \ 'i' : ['<Plug>(coc-implementation)'          , 'implementation'],
"       \ 'I' : [':CocList diagnostics'                , 'diagnostics'],
"       \ 'j' : ['<Plug>(coc-float-jump)'              , 'float jump'],
"       \ 'l' : ['<Plug>(coc-codelens-action)'         , 'code lens'],
"       \ 'n' : ['<Plug>(coc-diagnostic-next)'         , 'next diagnostic'],
"       \ 'N' : ['<Plug>(coc-diagnostic-next-error)'   , 'next error'],
"       \ 'o' : ['<Plug>(coc-openlink)'                , 'open link'],
"       \ 'O' : [':CocList outline'                    , 'outline'],
"       \ 'p' : ['<Plug>(coc-diagnostic-prev)'         , 'prev diagnostic'],
"       \ 'P' : ['<Plug>(coc-diagnostic-prev-error)'   , 'prev error'],
"       \ 'q' : ['<Plug>(coc-fix-current)'             , 'quickfix'],
"       \ 'r' : ['<Plug>(coc-rename)'                  , 'rename'],
"       \ 'R' : ['<Plug>(coc-references)'              , 'references'],
"       \ 's' : [':CocList -I symbols'                 , 'references'],
"       \ 'S' : [':CocList snippets'                   , 'snippets'],
"       \ 't' : ['<Plug>(coc-type-definition)'         , 'type definition'],
"       \ 'u' : [':CocListResume'                      , 'resume list'],
"       \ 'U' : [':CocUpdate'                          , 'update CoC'],
"       \ 'v' : [':Vista!!'                            , 'tag viewer'],
"       \ 'z' : [':CocDisable'                         , 'disable CoC'],
"       \ 'Z' : [':CocEnable'                          , 'enable CoC'],
"       \ }

" " t is for terminal
" let g:which_key_map.t = {
"       \ 'name' : '+terminal' ,
"       \ ';' : [':FloatermNew --wintype=popup --height=6'        , 'terminal'],
"       \ 'f' : [':FloatermNew fzf'                               , 'fzf'],
"       \ 'g' : [':FloatermNew lazygit'                           , 'git'],
"       \ 'd' : [':FloatermNew lazydocker'                        , 'docker'],
"       \ 'n' : [':FloatermNew node'                              , 'node'],
"       \ 'N' : [':FloatermNew nnn'                               , 'nnn'],
"       \ 'p' : [':FloatermNew python'                            , 'python'],
"       \ 'r' : [':FloatermNew ranger'                            , 'ranger'],
"       \ 't' : [':FloatermToggle'                                , 'toggle'],
"       \ 'y' : [':FloatermNew ytop'                              , 'ytop'],
"       \ 's' : [':FloatermNew ncdu'                              , 'ncdu'],
"       \ }

