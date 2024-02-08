-- NOTE: this is a remote plugin written in Python, so it requires the `pynvim` package to be installed
-- I've created a "pynvim" venv for neovim and installed pynvim and CopilotChat.nvim's pip dependencies there
-- see: https://github.com/neovim/pynvim/issues/498#issuecomment-1114461723
-- see: https://github.com/CopilotC-Nvim/CopilotChat.nvim?tab=readme-ov-file#installation

-- NOTE: solve "ambiguous use of user-defined command" error by restarting nvim + :UpdateRemotePlugins
-- see: https://github.com/jellydn/CopilotChat.nvim/issues/43#issuecomment-1923807768
return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    opts = {
      debug = false, -- Enable or disable debug mode, the log file will be in ~/.local/state/nvim/CopilotChat.nvim.log
      disable_extra_info = 'no', -- Disable extra information (e.g: system prompt) in the response.
      prompts = {
        Explain = 'Please explain how the following code works.',
        Review = 'Please review the following code and provide suggestions for improvement.',
        Tests = 'Please explain how the selected code works, then generate unit tests for it.',
        Refactor = 'Please refactor the following code to improve its clarity and readability.',
        FixCode = 'Please fix the following code to make it work as intended.',
        BetterNamings = 'Please provide better names for the following variables and functions.',
        Documentation = 'Please provide documentation for the following code.',
        -- Text related prompts
        Summarize = 'Please summarize the following text.',
        Spelling = 'Please correct any grammar and spelling errors in the following text.',
        Wording = 'Please improve the grammar and wording of the following text.',
        Concise = 'Please rewrite the following text to make it more concise.',
      },
      show_help = 'yes', -- Show help text for CopilotChatInPlace, default: yes
    },
    build = function()
      vim.notify("Please update the remote plugins by running ':UpdateRemotePlugins', then restart Neovim.")
    end,
    event = 'VeryLazy',
    keys = {
      -- Code related commands
      { '<leader>cce', '<cmd>CopilotChatExplain<cr>', desc = 'CopilotChat - Explain code' },
      { '<leader>cct', '<cmd>CopilotChatTests<cr>', desc = 'CopilotChat - Generate tests' },
      { '<leader>ccr', '<cmd>CopilotChatReview<cr>', desc = 'CopilotChat - Review code' },
      { '<leader>ccR', '<cmd>CopilotChatRefactor<cr>', desc = 'CopilotChat - Refactor code' },
      { '<leader>ccf', '<cmd>CopilotChatFixCode<cr>', desc = 'CopilotChat - Fix code' },
      { '<leader>ccb', '<cmd>CopilotChatBetterNamings<cr>', desc = 'CopilotChat - Better Name' },
      { '<leader>ccd', '<cmd>CopilotChatDocumentation<cr>', desc = 'CopilotChat - Add documentation for code' },
      -- Text related commands
      { '<leader>ccs', '<cmd>CopilotChatSummarize<cr>', desc = 'CopilotChat - Summarize text' },
      { '<leader>ccS', '<cmd>CopilotChatSpelling<cr>', desc = 'CopilotChat - Correct spelling' },
      { '<leader>ccw', '<cmd>CopilotChatWording<cr>', desc = 'CopilotChat - Improve wording' },
      { '<leader>ccc', '<cmd>CopilotChatConcise<cr>', desc = 'CopilotChat - Make text concise' },
      -- Chat with Copilot in visual mode
      {
        '<leader>ccv',
        ':CopilotChatVisual',
        mode = 'x',
        desc = 'CopilotChat - Open in vertical split',
      },
      {
        '<leader>ccx',
        ':CopilotChatInPlace<cr>',
        mode = 'x',
        desc = 'CopilotChat - Run in-place code',
      },
      -- Custom input for CopilotChat
      {
        '<leader>cci',
        function()
          local input = vim.fn.input('Ask Copilot: ')
          if input ~= '' then
            vim.cmd('CopilotChat ' .. input)
          end
        end,
        desc = 'CopilotChat - Ask input',
      },
      -- Generate commit message base on the git diff
      {
        '<leader>ccm',
        function()
          local diff = get_git_diff()
          if diff ~= '' then
            vim.fn.setreg('"', diff)
            vim.cmd('CopilotChat Write commit message for the change with commitizen convention.')
          end
        end,
        desc = 'CopilotChat - Generate commit message for all changes',
      },
      {
        '<leader>ccM',
        function()
          local diff = get_git_diff(true)
          if diff ~= '' then
            vim.fn.setreg('"', diff)
            vim.cmd('CopilotChat Write commit message for the change with commitizen convention.')
          end
        end,
        desc = 'CopilotChat - Generate commit message for staged changes',
      },
      -- Debug
      { '<leader>ccD', '<cmd>CopilotChatDebugInfo<cr>', desc = 'CopilotChat - Debug Info' },
    },
  },
}
