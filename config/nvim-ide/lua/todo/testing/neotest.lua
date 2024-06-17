--  TODO: https://www.lazyvim.org/extras/test/core

return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    { 'folke/neodev.nvim', opts = { library = { plugins = { 'neotest' }, types = true } } },
    {
      'folke/which-key.nvim',
      opts = {
        defaults = {
          ['<leader>t'] = { name = 'Test' },
        },
      },
    },
  },
  keys = function()
  -- stylua: ignore
    return {
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run last" },
      { "<leader>tn", function() require("neotest").run.run() end, desc = "Run nearest" },
      { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show output" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle summary" },
      { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop" },
      { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file" },
      { "<leader>tT", function() require("neotest").run.run(vim.loop.cwd()) end, desc = "Run all test files" },
      -- TODO: do these watch commands work with all adapters?
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Watch file (toggle)" },
      { "<leader>tW", function() require("neotest").watch.toggle(vim.loop.cwd()) end, desc = "Watch all test files (toggle)" },
    } 
  end,
}
