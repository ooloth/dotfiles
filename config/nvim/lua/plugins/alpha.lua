local Util = require('lazyvim.util')

return {
  'goolord/alpha-nvim',
  opts = function()
    local dashboard = require('alpha.themes.dashboard')
    local logo = [[
  ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z
  ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z    
  ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z       
  ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z         
  ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║
  ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝
  ]]

    dashboard.section.header.val = vim.split(logo, '\n')
    dashboard.section.buttons.val = {
      dashboard.button('s', '󰑓 ' .. ' Restore Session', [[:lua require("persistence").load() <cr>]]),
      dashboard.button('r', ' ' .. ' Recent files', ':Telescope oldfiles cwd_only=true<cr>'),
      dashboard.button('f', ' ' .. ' Find file', ':Telescope git_files<cr>'),
      dashboard.button('g', ' ' .. ' Grep text', ':Telescope live_grep<cr>'),
      dashboard.button('n', ' ' .. ' New file', ':ene <BAR> startinsert<cr>'),
      dashboard.button('l', '󰒲 ' .. ' Lazy', ':Lazy<cr>'),
      dashboard.button('q', ' ' .. ' Quit', ':qa<cr>'),
    }
    for _, button in ipairs(dashboard.section.buttons.val) do
      button.opts.hl = 'AlphaButtons'
      button.opts.hl_shortcut = 'AlphaShortcut'
    end
    dashboard.section.footer.opts.hl = 'Type'
    dashboard.section.header.opts.hl = 'AlphaHeader'
    dashboard.section.buttons.opts.hl = 'AlphaButtons'
    dashboard.opts.layout[1].val = 8
    return dashboard
  end,
}