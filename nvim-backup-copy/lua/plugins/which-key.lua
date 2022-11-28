require('which-key').setup({})

local wk = require("which-key")

vim.g.mapleader = " "

local mappings = {
  ["/"] = { "<cmd>Commentary<CR>", "Comment" },
  ["c"] = { "<cmd>BufferClose!<CR>", "Close Buffer" },
  ["d"] = { "<cmd>Telescope lsp_document_diagnostics<cr>", "Diagnostics in buffer" },
  ["D"] = { "<cmd>Telescope lsp_workspace_diagnostics<cr>", "Diagnostics in workspace" },
  ["e"] = { "<cmd>NvimTreeFindFile<cr>", "Explore" },

  f = {
    name = "Find",
    b = { "<cmd>Telescope buffers<cr>", "Buffer" },
    c = { "<cmd>Telescope commands<cr>", "Command" },
    C = { "<cmd>lua require('telescope.builtin.internal').colorscheme({enable_preview = true})<cr>", "Colorscheme" },
    f = { "<cmd>Telescope git_files<cr>", "File" },
    h = { "<cmd>Telescope help_tags<cr>", "Help tag" },
    k = { "<cmd>Telescope keymaps<cr>", "Keymap" },
    M = { "<cmd>Telescope man_pages<cr>", "Man page" },
    R = { "<cmd>Telescope registers<cr>", "Register" },
    s = { "<cmd>Telescope lsp_document_symbols<cr>", "Symbol in document" },
    t = { "<cmd>Telescope live_grep<cr>", "Text" },
  },

  g = {
    name = "Git",
    A = { '<cmd>Git add .<CR>', 'add all' },
    b = { '<cmd>Telescope git_branches<CR>', 'Check out a branch' },
    B = { '<cmd>Git blame<CR>', 'blame' },
    c = { '<cmd>Telescope git_bcommits<CR>', 'Check out commit (buffer)' },
    C = { '<cmd>Telescope git_commits<CR>', 'Check out commit (repo)' },
    d = { '<cmd>vert Gdiff<CR>', 'diff' },
    g = { '<cmd>GGrep<CR>', 'git grep' },
    h = { '<cmd>Telescope git_stash<CR>', 'Apply a stash' },
    p = { '<cmd>Git push<CR>', 'push' },
    P = { '<cmd>Git pull --ff<CR>', 'pull (ff when possible)' },
    s = { '<cmd>vert Git<cr>', 'status (in split)' },
    S = { '<cmd>tab Git<cr>', 'status (in tab)' },
  },

  ["h"] = { '<cmd>let @/=""<CR>', "No Highlight" },

  p = {
    name = "Packer",
    c = { "<cmd>PackerCompile<cr>", "Compile" },
    i = { "<cmd>PackerInstall<cr>", "Install" },
    r = { "<cmd>lua require('lv-utils').reload_lv_config()<cr>", "Reload" },
    s = { "<cmd>PackerSync<cr>", "Sync" },
    u = { "<cmd>PackerUpdate<cr>", "Update" },
  },

  ["q"] = { "<cmd>q<CR>", "Quit" },

  ["r"] = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename symbol" },

  s = {
    name = 'Session',
    d = { '<cmd>SDelete<cr>', 'delete' },
    s = { '<cmd>SSave<cr>', 'save' },
    x = { '<cmd>SClose<cr>', 'exit' },
  },

  ["w"] = { "<cmd>w!<CR>", "Save" },

  -- cmd([[

-- " ------------------------------------------------------------------------
-- " NORMAL + VISUAL MODE
-- " ------------------------------------------------------------------------


-- " ------------------------------------------------------------------------
-- " NORMAL MODE ONLY
-- " ------------------------------------------------------------------------

-- " Navigate between buffers
-- nnoremap <TAB>   :bnext<CR>
-- nnoremap <S-TAB> :bprevious<CR>

-- " ------------------------------------------------------------------------
-- " INSERT MODE ONLY
-- " ------------------------------------------------------------------------

-- " Better nav for omnicomplete
-- inoremap <expr> <c-n> ("\<C-n>")
-- inoremap <expr> <c-e> ("\<C-p>")

-- " Accept suggestion with Enter
-- if exists('*complete_info')
--   inoremap <expr> <CR> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
-- else
--   inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
-- endif

-- " ------------------------------------------------------------------------
-- " TERMINAL MODE
-- " ------------------------------------------------------------------------

-- " Return to normal mode
-- tnoremap <Esc> <C-\><C-n>

-- " ------------------------------------------------------------------------
-- " WHICH KEY (leader key mappings)
-- " ------------------------------------------------------------------------

-- " Need at least one <Leader> mapping outside menu for Which Key menu delay to work
-- nnoremap <Leader>[ :vertical resize -5<CR>
-- nnoremap <Leader>] :vertical resize +5<CR>

-- " Initialize key map
-- let g:which_key_map =  {}

-- let g:which_key_map['='] = ['<C-w>='                                       , 'equal width windows']
-- let g:which_key_map['b'] = [':Telescope buffers'                           , 'buffer search']
-- let g:which_key_map['c'] = [':Telescope command_history'                   , 'command history' ]
-- let g:which_key_map['d'] = [':Bdelete menu'                                , 'delete buffers']
-- let g:which_key_map['e'] = [':exec "lua vim.lsp.diagnostic.set_loclist()"' , 'error list']

-- let g:which_key_map['f'] = {
--   \ 'name' : '+find',
--   \ 'f' : [':Telescope find_files', 'files'],
--   \ 'g' : [':Telescope git_files', 'git files'],
--   \ 'p' : [':Telescope live_grep', 'phrase'],
--   \ 'r' : [':Telescope lsp_references', 'references'],
--   \ 'R' : [':Telescope registers', 'registers'],
--   \ 's' : [':Telescope lsp_document_symbols', 'symbols'],
--   \ }

-- nnoremap <leader>vrn :lua vim.lsp.buf.rename()<CR>
-- nnoremap <leader>vsd :lua vim.lsp.diagnostic.show_line_diagnostics()<CR>

-- let g:which_key_map['g'] = {
--   \ 'name' : '+git' ,
--   \ 'A' : [':Git add .'              , 'add all'],
--   \ 'b' : [':Telescope git_branches' , 'branches (local + remote)'],
--   \ 'B' : [':Git blame'              , 'blame'],
--   \ 'c' : [':Telescope git_bcommits' , 'commits (buffer)'],
--   \ 'C' : [':Telescope git_commits'  , 'commits (repo)'],
--   \ 'd' : [':vert Gdiff'             , 'diff'],
--   \ 'g' : [':GGrep'                  , 'git grep'],
--   \ 'm' : [':Git move'               , 'move'],
--   \ 'p' : [':Git push --no-verify'   , 'push (no verify)'],
--   \ 'P' : [':Git pull --ff'          , 'pull (ff when possible)'],
--   \ 'r' : [':GRemove'                , 'remove'],
--   \ 's' : [':vert Git'               , 'status (in split)'],
--   \ 'S' : [':tab Git'                , 'status (in tab)'],
--   \ }

-- let g:which_key_map['h'] = [':let @/ = ""' , 'highlights off']

-- " let g:which_key_map['i'] = ['' , '' ]
-- " let g:which_key_map['j'] = ['' , '' ]

-- let g:which_key_map['k'] = [':Telescope keymaps'                                   , 'keymaps' ]
-- let g:which_key_map['l'] = [":normal \"ahiwlconsole.log('\<C-R>a:', \<C-R>a)\<CR>" , 'log to console']

-- " let g:which_key_map['m'] = ['', '' ]
-- " let g:which_key_map['n'] = ['', '']

-- let g:which_key_map['o'] = [':Vifm', 'open file tree']

-- " let g:which_key_map['p'] = ['', 'snippets']

-- let g:which_key_map['q'] = [':q'                              , 'quit window']
-- let g:which_key_map['r'] = [':source ~/.config/nvim/init.vim' , 'reload neovim']

-- " Vim Test
-- " let g:which_key_map['t'] = {
-- "   \ 'name' : '+test' ,
-- "   \ 'f' : [':TestFile'    , 'file's tests (or last run file's tests)'],
-- "   \ 'l' : [':TestLast'    , 'last test'],
-- "   \ 'n' : [':TestNearest' , 'nearest test to cursor'],
-- "   \ 's' : [':TestSuite'   , 'suite of tests'],
-- "   \ 'v' : [':TestVisit'   , 'visit file with last run tests'],
-- "   \}

-- let g:which_key_map['u'] = [':UndotreeShow'                         , 'undo list']
-- let g:which_key_map['v'] = ['<C-w>v'                                , 'vertical split']
-- let g:which_key_map['w'] = [':write | edit | TSBufEnable highlight' , 'write buffer']

-- " let g:which_key_map['x'] = ['', '']
-- " let g:which_key_map['y'] = ['', 'yank list']
-- " let g:which_key_map['z'] = ['', '']

-- ]])
}

local opts = {
  mode = "n", -- NORMAL mode
  prefix = "<leader>",
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = true, -- use `nowait` when creating keymaps
}

wk.register(mappings, opts)
