-- see: https://wezfurlong.org/wezterm/config/lua/config/index.html

local wezterm = require('wezterm')
local config = {}

config.cell_width = 0.9 -- see: https://wezfurlong.org/wezterm/colorschemes/index.html
config.color_scheme = 'Catppuccin Mocha' -- see: https://wezfurlong.org/wezterm/colorschemes/c/index.html#catppuccin-mocha
-- config.color_scheme = 'Dracula' -- see: https://wezfurlong.org/wezterm/colorschemes/index.html
-- config.color_scheme = 'MaterialOcean' -- see: https://wezfurlong.org/wezterm/colorschemes/index.html
config.enable_tab_bar = false
config.font = wezterm.font('Ubuntu Mono') -- see: https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
config.font_size = 16
config.line_height = 1.28
config.window_decorations = 'RESIZE'
-- config.window_padding = {
--   left = 0,
--   right = 0,
--   top = 0,
--   bottom = 0,
-- }

return config
