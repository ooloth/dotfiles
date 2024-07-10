return {
  'folke/noice.nvim',
  dependencies = {
    -- see: https://github.com/folke/noice.nvim?tab=readme-ov-file#%EF%B8%8F-requirements
    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
    'MunifTanjim/nui.nvim', -- used for proper rendering and multiple views
    { 'rcarriga/nvim-notify', opts = { background_colour = '#1A1A28' } }, -- use as vim.notify UI
    'nvim-treesitter/nvim-treesitter',
  },
  event = 'VeryLazy',
  opts = {
    -- see: https://github.com/folke/noice.nvim?tab=readme-ov-file#-installation
    -- see: https://github.com/folke/noice.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
    -- see: https://github.com/folke/noice.nvim/wiki/Configuration-Recipes
    -- see: https://www.lazyvim.org/plugins/ui#noicenvim
    lsp = {
      hover = {
        opts = {
          border = {
            style = 'rounded',
            padding = { 0, 1 },
          },
        },
      },
      -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
      override = {
        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
        ['vim.lsp.util.stylize_markdown'] = true,
        ['cmp.entry.get_documentation'] = true, -- requires hrsh7th/nvim-cmp
      },
    },
    presets = {
      bottom_search = false, -- use a classic bottom cmdline for search
      command_palette = true, -- position the cmdline and popupmenu together
      long_message_to_split = true, -- long messages will be sent to a split
      inc_rename = false, -- enables an input dialog for inc-rename.nvim
      lsp_doc_border = false, -- add a border to hover docs and signature help
    },
    routes = {
      {
        -- show @recording messages (https://github.com/folke/noice.nvim/wiki/Configuration-Recipes#show-recording-messages)
        view = 'notify',
        filter = { event = 'msg_showmode' },
      },
      {
        -- send "written" messages to mini view instead of notify view (https://www.lazyvim.org/plugins/ui#noicenvim)
        filter = {
          event = 'msg_show',
          any = {
            { find = '%d+L, %d+B' },
            { find = '; after #%d+' },
            { find = '; before #%d+' },
          },
        },
        view = 'mini',
      },
      -- filter out "written" messages (https://github.com/folke/noice.nvim/wiki/Configuration-Recipes#hide-written-messages)
      -- {
      --   filter = {
      --     event = "msg_show",
      --     kind = "",
      --     find = "written",
      --   },
      --   opts = { skip = true },
      -- },
    },
  },
}
