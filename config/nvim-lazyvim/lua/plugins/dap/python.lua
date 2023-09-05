return {
  -- {lua require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')}
  {
    'mfussenegger/nvim-dap-python',
    event = 'VeryLazy',
    dependencies = { 'mfussenegger/nvim-dap' },
    config = function()
      require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')
      -- local dap = require('dap')
      -- dap.adapters.python = {
      --   type = 'executable',
      --   command = 'python',
      --   args = { '-m', 'debugpy.adapter' },
      -- }
      -- dap.configurations.python = {
      --   {
      --     type = 'python',
      --     request = 'launch',
      --     name = 'Launch file',
      --     program = '${file}', -- This configuration will launch the current file if used.
      --   },
      -- }
    end,
  },
}
