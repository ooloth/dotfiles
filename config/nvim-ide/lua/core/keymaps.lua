local set = vim.keymap.set

vim.g.mapleader = ' '

-- swap : and ,
set({ 'n', 'v' }, ',', ':') -- enter command mode with , instead of :
set({ 'n', 'v' }, ':', ',') -- navigate f and t results using ;/: (like n/N for / results)

-- line beginning + end
set({ 'n', 'v' }, '<S-h>', '^', { silent = true })
set({ 'n', 'v' }, '<S-l>', '$', { silent = true })
set({ 'n', 'v' }, '$', '<Esc>', { silent = true }) -- practice using L instead

-- clear search highlights
set('n', '<esc>', '<cmd>nohlsearch<CR><Esc>', { silent = true })
