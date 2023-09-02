local wezterm = require 'wezterm'
local config = {}

config.color_scheme = 'Dracula' -- see: https://wezfurlong.org/wezterm/colorschemes/index.html
config.color_scheme = 'MaterialOcean' -- see: https://wezfurlong.org/wezterm/colorschemes/index.html
config.enable_tab_bar = false
config.font = wezterm.font 'Ubuntu Mono' -- see: https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
config.font_size = 15
config.line_height = 1.35
config.window_decorations = 'RESIZE'

return config
