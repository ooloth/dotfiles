-- see: https://github.com/jellydn/lazy-nvim-ide/blob/main/lua/plugins/extras/copilot-chat.lua
---Get all the changes in the git repository
---@param staged? boolean
---@return string
local function get_git_diff(staged)
  local cmd = staged and 'git diff --staged' or 'git diff'
  local handle = io.popen(cmd)
  if not handle then
    return ''
  end

  local result = handle:read('*a')
  handle:close()
  return result
end

-- NOTE: this is a remote plugin written in Python, so it requires the `pynvim` package to be installed
-- I've created a "pynvim" venv for neovim and installed pynvim and CopilotChat.nvim's pip dependencies there
-- see: https://github.com/neovim/pynvim/issues/498#issuecomment-1114461723
-- see: https://github.com/CopilotC-Nvim/CopilotChat.nvim?tab=readme-ov-file#installation

-- NOTE: can solve "ambiguous use of user-defined command" error by restarting nvim + :UpdateRemotePlugins
-- see: https://github.com/jellydn/CopilotChat.nvim/issues/43#issuecomment-1923807768
return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      {
        'folke/which-key.nvim',
        opts = {
          defaults = {
            ['<leader>a'] = { name = 'AI' },
          },
        },
      },
    },
    opts = {
      debug = false, -- Enable or disable debug mode
      disable_extra_info = 'no', -- Disable extra information in the response
      hide_system_prompt = 'yes', -- Hide system prompts in the response
      prompts = { -- Set dynamic prompts for CopilotChat commands
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
      proxy = '', -- Proxies requests via https or socks
      show_help = 'yes', -- Show help text for CopilotChatInPlace
    },
    build = function()
      vim.notify("Please update the remote plugins by running ':UpdateRemotePlugins', then restart Neovim.")
    end,
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      -- Custom input for CopilotChat
      { '<leader>aa', function()
          local input = vim.fn.input('Ask Copilot: ')
          if input ~= '' then
            vim.cmd('CopilotChat ' .. input)
          end
        end,
        desc = 'Ask for something else',
      },
      -- Code related commands
      { "<leader>ab", "<cmd>CopilotChatVsplitToggle<cr>", desc = "Toggle vertical split" },
      { '<leader>ac', '<cmd>CopilotChatConcise<cr>', desc = 'Make text concise' },
      { '<leader>ad', '<cmd>CopilotChatDocumentation<cr>', desc = 'Add documentation for code' },
      { '<leader>aD', '<cmd>CopilotChatDebugInfo<cr>', desc = 'Debug Info' },
      { '<leader>ae', '<cmd>CopilotChatExplain<cr>', desc = 'Explain code' },
      { '<leader>af', '<cmd>CopilotChatFixCode<cr>', desc = 'Fix code' },
      { '<leader>ai', '<cmd>CopilotChatInPlace<cr>', mode = 'x', desc = 'Discuss selection in float' },
      { '<leader>al', '<cmd>CopilotChatSpelling<cr>', desc = 'Correct spelling' },
      { '<leader>an', '<cmd>CopilotChatBetterNamings<cr>', desc = 'Better Name' },
      { '<leader>ar', '<cmd>CopilotChatReview<cr>', desc = 'Review code' },
      { '<leader>aR', '<cmd>CopilotChatRefactor<cr>', desc = 'Refactor code' },
      { '<leader>as', '<cmd>CopilotChatVisual<cr>', mode = 'x', desc = 'Discuss selection in split' },
      { '<leader>at', '<cmd>CopilotChatTests<cr>', desc = 'Generate tests' },
      { '<leader>aw', '<cmd>CopilotChatWording<cr>', desc = 'Improve wording' },
      { '<leader>az', '<cmd>CopilotChatSummarize<cr>', desc = 'Summarize text' },

      -- Generate commit message base on the git diff
      {
        '<leader>am',
        function()
          local diff = get_git_diff()
          if diff ~= '' then
            vim.fn.setreg('"', diff)
            vim.cmd('CopilotChat Write commit message for the change with commitizen convention.')
          end
        end,
        desc = 'Generate commit message for all changes',
      },
      {
        '<leader>aM',
        function()
          local diff = get_git_diff(true)
          if diff ~= '' then
            vim.fn.setreg('"', diff)
            vim.cmd('CopilotChat Write commit message for the change with commitizen convention.')
          end
        end,
        desc = 'Generate commit message for staged changes',
      },
    },
  },
}
