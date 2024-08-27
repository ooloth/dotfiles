-- TODO: https://www.lazyvim.org/plugins/linting
-- see: https://github.com/mfussenegger/nvim-lint
-- see: https://www.lazyvim.org/plugins/linting#nvim-lint

return {
  'mfussenegger/nvim-lint',
  config = function()
    -- see: https://github.com/mfussenegger/nvim-lint#available-linters
    require('lint')

    -- see: https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#usage
    vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
      callback = function()
        -- try_lint without arguments runs the linters defined in `linters_by_ft` for the current filetype
        require('lint').try_lint()
      end,
    })
  end,
}
