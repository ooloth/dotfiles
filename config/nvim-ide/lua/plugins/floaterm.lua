-- TODO: toggle maximized for scratch terminal? if I use wintype=split, can I just use the normal leader-em? otherwise: https://github.com/voldikss/vim-floaterm/issues/57
-- TODO: FloatermNew yazi (more/less ergonomic than mini.files?)
-- TODO: https://github.com/voldikss/vim-floaterm?tab=readme-ov-file#advanced-topics

vim.g.floaterm_borderchars = ''
vim.g.floaterm_title = ''

local options = {
  lazygit = {
    '--silent',
    '--height=1.0',
    '--width=1.0',
    '--name=lazygit',
    'lazygit',
  },
  scratch = {
    '--silent',
    '--borderchars=─',
    '--height=0.33',
    '--width=1.0',
    '--position=bottom',
    '--name=scratch',
  },
}

-- see: https://github.com/voldikss/vim-floaterm/issues/409#issuecomment-2049837814
local function toggle_if_running_else_create(name)
  if vim.fn['floaterm#terminal#get_bufnr'](name) < 0 then
    vim.cmd.FloatermNew(options[name])
    vim.cmd.FloatermToggle(name)
  else
    vim.cmd.FloatermToggle(name)

    -- reapply options as a way to get the original height back after maximizing
    if vim.fn['floaterm#terminal#get_bufnr'](name) >= 0 then
      vim.cmd.FloatermUpdate(options[name])
    end
  end
end

return {
  {
    'voldikss/vim-floaterm',
    event = 'VeryLazy',
    cmd = 'FloatermNew',
    -- stylua: ignore
    keys = {
      { '<leader>gg', function() toggle_if_running_else_create('lazygit') end, desc = 'Lazygit' },
      { '<c-g>', function() toggle_if_running_else_create('lazygit') end, desc = 'Lazygit' },
      { '<c-g>', mode = 't', '<cmd>FloatermHide<cr>', desc = 'Hide Lazygit' },
      { '<c-t>', function() toggle_if_running_else_create('scratch') end, desc = 'Open scratch terminal' }, -- TODO: toggle most recent terminal instead?
      { '<c-t>', mode = 't', '<cmd>FloatermHide<cr>', desc = 'Hide terminal' },
      -- TODO: can the same keymap also toggle back if pressed while maximized?
      -- see: https://github.com/voldikss/vim-floaterm/issues/57#issuecomment-1110320601
      { '<c-m>', mode = 't', '<cmd>FloatermUpdate --height=1.0<cr>', desc = 'Maximize terminal' }, 
    },
    init = function()
      -- on startup, start hidden terminals so they're ready to appear instantly
      -- https://github.com/voldikss/vim-floaterm?tab=readme-ov-file#commands
      vim.cmd.FloatermNew(options['lazygit'])
      vim.cmd.FloatermNew(options['scratch'])

      -- use catppuccin mocha "surface1" for float border (same as split border)
      vim.cmd([[ hi FloatermBorder guifg=#45475a ]])

      -- TODO: find an ergonomic way to quit Lazygit without stopping its process?
      -- TODO: just get used to closing with <c-t> as I do with the scratch terminal and did in VS Code?
      -- FIXME: what follows interferes with typing "q" in commit messages...
      -- see: https://github.com/voldikss/vim-floaterm?tab=readme-ov-file#autocmd
      -- see: https://neovim.discourse.group/t/new-nvim-create-autocmd-for-user-custom-event-setup/2325
      -- vim.api.nvim_create_autocmd('User', {
      --   pattern = { 'FloatermOpen' },
      --   callback = function()
      --     -- local bufname = vim.fn.expand('%')
      --     if string.find(vim.fn.expand('%'), 'lazygit') then
      --       vim.keymap.set('t', 'q', '<cmd>FloatermHide<cr>', { desc = 'Hide Lazygit' })
      --     end
      --   end,
      -- })
    end,
  },
}
