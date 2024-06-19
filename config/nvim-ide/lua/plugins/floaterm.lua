-- TODO: remove timoutlen delay when pressing <esc> inside lazygit (make it feel sluggish); <esc><esc> is my "go to normal mode in a terminal" mapping, so I think that's the conflict
-- TODO: toggle maximized for scratch terminal? if I use wintype=split, can I just use the normal leader-em? otherwise: https://github.com/voldikss/vim-floaterm/issues/57
-- TODO: FloatermNew yazi (more/less ergonomic than mini.files?)
-- TODO: https://github.com/voldikss/vim-floaterm?tab=readme-ov-file#advanced-topics

vim.g.floaterm_borderchars = ''
vim.g.floaterm_title = ''

-- track values I want to toggle
local state = {
  lazygit = {
    height = {
      current = '1.0',
      default = '1.0',
      max = '1.0',
    },
  },
  scratch = {
    height = {
      current = '0.3',
      default = '0.3',
      max = '1.0',
    },
  },
}

local options = {
  lazygit = {
    '--silent',
    '--height=' .. state.lazygit.height.default,
    '--width=1.0',
    '--name=lazygit',
    'lazygit',
  },
  scratch = {
    '--silent',
    '--borderchars=─',
    '--height=' .. state.scratch.height.default,
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

local function toggle_maximized(name)
  local current_term_name = vim.fn['floaterm#config#get'](vim.fn.bufnr('%'), 'name')

  if name == current_term_name then
    -- if current_term_name ~= 'lazygit' then
    local height = state[name].height
    local new_height = height.current == height.max and height.default or height.max

    vim.cmd.FloatermUpdate('--height=' .. new_height)
    state[name].height.current = new_height
  end
end

return {
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
      { '<c-z>', mode = 't', function() toggle_maximized('scratch') end, desc = 'Toggle maximized terminal' }, 
    },
  init = function()
    -- at startup, start hidden terminals so they're ready to appear instantly (https://github.com/voldikss/vim-floaterm?tab=readme-ov-file#commands)
    vim.cmd.FloatermNew(options['lazygit'])
    vim.cmd.FloatermNew(options['scratch'])

    -- set float border to catppuccin mocha "surface1" color (used for split borders)
    vim.cmd([[ hi FloatermBorder guifg=#45475a ]])

    -- TODO: check if floaterm is open first (e.g. don't do this when creating tmux splits)
    -- automatically resize floating window if vim is resized
    -- see: https://github.com/voldikss/vim-floaterm/issues/296#issuecomment-1098841533
    vim.cmd([[ autocmd VimResized * FloatermUpdate ]])

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
}
