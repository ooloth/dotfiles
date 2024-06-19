-- TODO: FloatermNew yazi (more/less ergonomic than mini.files?)
-- TODO: https://github.com/voldikss/vim-floaterm?tab=readme-ov-file#advanced-topics

vim.g.floaterm_borderchars = ''
vim.g.floaterm_height = 0.65
vim.g.floaterm_title = ''
vim.g.floaterm_width = 0.65

local options = {
  lazygit = {
    '--silent',
    '--height=0.9999999999999999',
    '--width=0.9999999999999999',
    '--name=lazygit',
    'lazygit',
  },
  scratch = {
    '--silent',
    '--borderchars=─│─│┌┐┘└',
    '--name=scratch',
  },
}

-- see: https://github.com/voldikss/vim-floaterm/issues/409#issuecomment-2049837814
local function toggle_if_running_else_create(name)
  if vim.fn['floaterm#terminal#get_bufnr'](name) < 0 then
    vim.cmd.FloatermToggle(name)
  else
    vim.cmd.FloatermNew(options[name])
    vim.cmd.FloatermToggle(name)
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
      { '<c-t>', '<cmd>FloatermToggle scratch<cr>', desc = 'Open scratch terminal' },
      { '<c-t>', mode = 't', '<cmd>FloatermHide<cr>', desc = 'Hide terminal' },
    },
    init = function()
      -- on startup, start hidden terminals so they're ready to appear instantly
      -- https://github.com/voldikss/vim-floaterm?tab=readme-ov-file#commands
      vim.cmd.FloatermNew(options['lazygit'])
      vim.cmd.FloatermNew(options['scratch'])

      -- TODO: find an ergonomic way to quit Lazygit without stopping its process?
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
