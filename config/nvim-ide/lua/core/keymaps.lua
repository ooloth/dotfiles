-- see: https://www.lazyvim.org/configuration/general#keymaps

local set = vim.keymap.set

vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-------------
-- GENERAL --
-------------

-- swap : and ,
set({ 'n', 'v' }, ',', ':') -- enter command mode with , instead of :
set({ 'n', 'v' }, ':', ',') -- navigate f and t results using ;/: (like n/N for / results)

-- line beginning + end
set({ 'n', 'v' }, '<S-h>', '^', { silent = true })
set({ 'n', 'v' }, '<S-l>', '$', { silent = true })
-- set({ 'n', 'v' }, '$', '<Esc>', { silent = true }) -- practice using L instead

-- clear search highlights
set('n', '<esc>', '<cmd>nohlsearch<CR><Esc>', { silent = true })

-- terminal
set('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'Enter Normal Mode' }) -- FIXME: causes a timeoutlen delay closing floaterm buffers; exclude them from this handy shortcut?
set('t', '<c-h>', '<cmd>wincmd h<cr>', { desc = 'Go to Left Window' })
set('t', '<c-j>', '<cmd>wincmd j<cr>', { desc = 'Go to Lower Window' })
set('t', '<c-k>', '<cmd>wincmd k<cr>', { desc = 'Go to Upper Window' })
set('t', '<c-l>', '<cmd>wincmd l<cr>', { desc = 'Go to Right Window' })
set('t', '<c-/>', '<cmd>close<cr>', { desc = 'Hide Terminal' })
set('t', '<c-_>', '<cmd>close<cr>', { desc = 'which_key_ignore' })

------------------
-- ALPHABETICAL --
------------------

-- "changes"
set('n', ']c', 'g,', { desc = 'Next change' }) -- go to next change with g;
set('n', '[c', 'g;', { desc = 'Prev change' }) -- go to next change with g;
set('n', 'g;', 'g,', { desc = 'Next change' }) -- go to next change with g;
set('n', 'g:', 'g;', { desc = 'Prev change' }) -- go to previous change with g;

-- "debugger" (see dap.lua)

-- "editor" (buffer)
set('n', '<tab>', '<cmd>bnext<cr>', { desc = 'Next editor' })
set('n', '<s-tab>', '<cmd>bprevious<cr>', { desc = 'Prev editor' })
set('n', '<leader>`', '<cmd>e#<cr>', { desc = 'Other editor' }) -- switch to last buffer
set('n', '<leader>ed', '<cmd>bd<cr>', { desc = 'Close editor' }) -- switch to last buffer
set('n', '<leader>ee', '<cmd>e#<cr>', { desc = 'Other editor' }) -- switch to last buffer
-- Close all buffers except the current one (like leader-wo does for windows):
-- https://stackoverflow.com/a/42071865/8802485
set('n', '<leader>eo', '<cmd>%bd|e#<cr>', { desc = 'Only keep this editor' })

-- "git" (see git.lua)
-- set({ 'n', 'v' }, '<leader>gg', '<cmd>FloatermNew lazygit<cr>', { desc = 'Lazygit' })

-- "help" (see telescope.lua)

-- "inspect" / "info"
-- highlights under cursor
set('n', '<leader>ic', vim.show_pos, { desc = 'Inspect Pos' })

-- "jumps" (see telescope.lua)
-- "keymaps" (see telescope.lua)
-- "lazy" / "LSP" (see lsp.lua)
-- "mason" (see lsp.lua)
-- "null-ls" (see lsp.lua)

-- "open"
set('n', 'gl', '<cmd>lopen<cr>', { desc = 'Location list' })
set('n', 'gq', '<cmd>botright copen<cr>', { desc = 'Quickfix list' })
set('n', '<leader>ol', '<cmd>lopen<cr>', { desc = 'Location list' }) -- use ]l + [l to navigate
set('n', '<leader>oq', '<cmd>copen<cr>', { desc = 'Quickfix list' }) -- use ]q + [q to navigate
set('n', '<leader>on', ':ene <BAR> startinsert<cr>', { desc = 'New file' })
-- '<leader>ot' = 'Terminal' (see vim-floaterm.lua)

-- "pin" (see mini-bufremove.lua + bufferline.lua)

-- "quit"
set('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit All' })

-- "replace" (see spectre.lua + lsp.lua)

-- "save"
set('n', '<leader><space>', '<cmd>w<cr>', { desc = 'Save' })

-- "tab"
set('n', ']<tab>', '<cmd>tabnext<cr>', { desc = 'Next tab' })
set('n', '[<tab>', '<cmd>tabprevious<cr>', { desc = 'Next tab' })
set('n', '<leader><tab><tab>', '<cmd>tabnew<cr>', { desc = 'New tab' })
set('n', '<leader><tab>]', '<cmd>tabnext<cr>', { desc = 'Next tab' })
set('n', '<leader><tab>n', '<cmd>tabnext<cr>', { desc = 'Next tab' })
set('n', '<leader><tab>[', '<cmd>tabprevious<cr>', { desc = 'Prev tab' })
set('n', '<leader><tab>p', '<cmd>tabprevious<cr>', { desc = 'Prev tab' })
set('n', '<leader><tab>o', '<cmd>tabonly<cr>', { desc = 'Close other tabs' })
set('n', '<leader><tab>d', '<cmd>tabclose<cr>', { desc = 'Close tab' })
set('n', '<leader><tab>f', '<cmd>tabfirst<cr>', { desc = 'First tab' })
set('n', '<leader><tab>l', '<cmd>tablast<cr>', { desc = 'Last tab' })

-- "ui"
-- "v"

-- "window"
-- TODO: map all <c-w> commands?
set('n', '<leader>\\', '<c-w>v', { desc = 'Split right' })
set('n', '<leader>w\\', '<c-w>v', { desc = 'Split right' })
set('n', '<leader>-', '<c-w>s', { desc = 'Split below' })
set('n', '<leader>w-', '<c-w>s', { desc = 'Split below' })
set('n', '<leader>=', '<c-w>=', { desc = 'Resize equally' })
set('n', '<leader>w=', '<c-w>=', { desc = 'Resize equally' })
set('n', '<leader>[', '<cmd>vertical resize -3<cr>', { desc = 'Reduce size' })
set('n', '<leader>w[', '<cmd>vertical resize -3<cr>', { desc = 'Reduce size' })
set('n', '<leader>]', '<cmd>vertical resize +3<cr>', { desc = 'Increase size' })
set('n', '<leader>w]', '<cmd>vertical resize +3<cr>', { desc = 'Increase size' })
set('n', '<leader>wd', '<c-w>c', { desc = 'Delete Window', remap = true })
set('n', '<leader>wh', '<c-w>h', { desc = 'Go left one window' })
set('n', '<leader>wj', '<c-w>j', { desc = 'Go down one window' })
set('n', '<leader>wk', '<c-w>k', { desc = 'Go up one window' })
set('n', '<leader>wl', '<c-w>l', { desc = 'Go right one window' })
-- TODO: "leader-wm" = toggle maximize window (see vim-maximizer.lua}
-- set("n", "<leader>wm", function() LazyVim.toggle.maximize() end, { desc = "Maximize Toggle" })
set('n', '<leader>wo', '<c-w>o', { desc = 'Only keep this one' })
set('n', '<leader>wt', '<cmd>tab split<cr>', { desc = 'Open in new tab' })
set('n', '<leader>ww', '<c-w>p', { desc = 'Other Window', remap = true })
-- TODO: "leader-ww" = pick window (see nvim-window-picker.lua)?

-- "x" ("diagnostics")
-- "y"
-- "z"

-- better up/down
set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
set({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })
set({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

-- Resize window using <ctrl> arrow keys
set('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase Window Height' })
set('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease Window Height' })
set('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease Window Width' })
set('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase Window Width' })

-- Move Lines
set('n', '<A-j>', '<cmd>m .+1<cr>==', { desc = 'Move Down' })
set('n', '<A-k>', '<cmd>m .-2<cr>==', { desc = 'Move Up' })
set('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move Down' })
set('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move Up' })
set('v', '<A-j>', ":m '>+1<cr>gv=gv", { desc = 'Move Down' })
set('v', '<A-k>', ":m '<-2<cr>gv=gv", { desc = 'Move Up' })

-- buffers
set('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Prev Buffer' })
set('n', '<S-l>', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
set('n', '[b', '<cmd>bprevious<cr>', { desc = 'Prev Buffer' })
set('n', ']b', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
set('n', '<leader>bb', '<cmd>e #<cr>', { desc = 'Switch to Other Buffer' })
set('n', '<leader>`', '<cmd>e #<cr>', { desc = 'Switch to Other Buffer' })
-- set('n', '<leader>bd', LazyVim.ui.bufremove, { desc = 'Delete Buffer' })
set('n', '<leader>bD', '<cmd>:bd<cr>', { desc = 'Delete Buffer and Window' })

-- Clear search with <esc>
set({ 'i', 'n' }, '<esc>', '<cmd>noh<cr><esc>', { desc = 'Escape and Clear hlsearch' })

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
set(
  'n',
  '<leader>ur',
  '<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>',
  { desc = 'Redraw / Clear hlsearch / Diff Update' }
)

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
set('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next Search Result' })
set('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next Search Result' })
set('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next Search Result' })
set('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev Search Result' })
set('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev Search Result' })
set('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev Search Result' })

-- Add undo break-points
set('i', ',', ',<c-g>u')
set('i', '.', '.<c-g>u')
set('i', ';', ';<c-g>u')

-- save file
set({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })

--keywordprg
set('n', '<leader>K', '<cmd>norm! K<cr>', { desc = 'Keywordprg' })

-- better indenting
set('v', '<', '<gv')
set('v', '>', '>gv')

-- commenting
set('n', 'gco', 'o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add Comment Below' })
set('n', 'gcO', 'O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add Comment Above' })

-- lazy
set('n', '<leader>l', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- new file
set('n', '<leader>fn', '<cmd>enew<cr>', { desc = 'New File' })

set('n', '<leader>xl', '<cmd>lopen<cr>', { desc = 'Location List' })
set('n', '<leader>xq', '<cmd>copen<cr>', { desc = 'Quickfix List' })

set('n', '[q', vim.cmd.cprev, { desc = 'Prev Quickfix' })
set('n', ']q', vim.cmd.cnext, { desc = 'Next Quickfix' })

-- diagnostic
local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end
set('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
set('n', ']d', diagnostic_goto(true), { desc = 'Next Diagnostic' })
set('n', '[d', diagnostic_goto(false), { desc = 'Prev Diagnostic' })
set('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
set('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Prev Error' })
set('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
set('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Prev Warning' })

-- stylua: ignore start

-- toggle options
-- set("n", "<leader>uf", function() LazyVim.format.toggle() end, { desc = "Toggle Auto Format (Global)" })
-- set("n", "<leader>uF", function() LazyVim.format.toggle(true) end, { desc = "Toggle Auto Format (Buffer)" })
-- set("n", "<leader>us", function() LazyVim.toggle("spell") end, { desc = "Toggle Spelling" })
-- set("n", "<leader>uw", function() LazyVim.toggle("wrap") end, { desc = "Toggle Word Wrap" })
-- set("n", "<leader>uL", function() LazyVim.toggle("relativenumber") end, { desc = "Toggle Relative Line Numbers" })
-- set("n", "<leader>ul", function() LazyVim.toggle.number() end, { desc = "Toggle Line Numbers" })
-- set("n", "<leader>ud", function() LazyVim.toggle.diagnostics() end, { desc = "Toggle Diagnostics" })
-- local conceallevel = vim.o.conceallevel > 0 and vim.o.conceallevel or 3
-- set("n", "<leader>uc", function() LazyVim.toggle("conceallevel", false, {0, conceallevel}) end, { desc = "Toggle Conceal" })
-- if vim.lsp.buf.inlay_hint or vim.lsp.inlay_hint then
--   set( "n", "<leader>uh", function() LazyVim.toggle.inlay_hints() end, { desc = "Toggle Inlay Hints" })
-- end
-- set("n", "<leader>uT", function() if vim.b.ts_highlight then vim.treesitter.stop() else vim.treesitter.start() end end, { desc = "Toggle Treesitter Highlight" })
-- set("n", "<leader>ub", function() LazyVim.toggle("background", false, {"light", "dark"}) end, { desc = "Toggle Background" })

-- -- lazygit
-- set("n", "<leader>gg", function() LazyVim.lazygit( { cwd = LazyVim.root.git() }) end, { desc = "Lazygit (Root Dir)" })
-- set("n", "<leader>gG", function() LazyVim.lazygit() end, { desc = "Lazygit (cwd)" })
-- set("n", "<leader>gb", LazyVim.lazygit.blame_line, { desc = "Git Blame Line" })
-- set("n", "<leader>gB", LazyVim.lazygit.browse, { desc = "Git Browse" })

-- set("n", "<leader>gf", function()
--   local git_path = vim.api.nvim_buf_get_name(0)
--   LazyVim.lazygit({args = { "-f", vim.trim(git_path) }})
-- end, { desc = "Lazygit Current File History" })

-- set("n", "<leader>gl", function()
--   LazyVim.lazygit({ args = { "log" }, cwd = LazyVim.root.git() })
-- end, { desc = "Lazygit Log" })
-- set("n", "<leader>gL", function()
--   LazyVim.lazygit({ args = { "log" } })
-- end, { desc = "Lazygit Log (cwd)" })
