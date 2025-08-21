-- see: https://wezfurlong.org/wezterm/config/lua/config/index.html

local wezterm = require('wezterm')
local config = {}

config.cell_width = 0.9 -- see: https://wezfurlong.org/wezterm/colorschemes/index.html
config.color_scheme = 'Catppuccin Mocha' -- see: https://wezfurlong.org/wezterm/colorschemes/c/index.html#catppuccin-mocha
-- config.color_scheme = 'Dracula' -- see: https://wezfurlong.org/wezterm/colorschemes/index.html
-- config.color_scheme = 'MaterialOcean' -- see: https://wezfurlong.org/wezterm/colorschemes/index.html
config.colors = {
  foreground = 'black',
}
config.enable_tab_bar = false
config.font = wezterm.font('UbuntuMono Nerd Font') -- see: https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
-- config.font = wezterm.font_with_fallback({ 'UbuntuMono Nerd Font', 'Apple Color Emoji' }) -- see: https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
config.font_size = 16
config.line_height = 1.28
config.window_decorations = 'RESIZE'
config.window_padding = {
  top = 6,
  right = 8,
  bottom = 6,
  left = 8,
}

-- see: https://github.com/wez/wezterm/issues/1124#issuecomment-1755513743
local center_content = function(window, pane)
  local win_dim = window:get_dimensions()
  local tab_dim = pane:tab():get_size()
  local overrides = window:get_config_overrides() or {}
  local padding_left = (win_dim.pixel_width - tab_dim.pixel_width) / 2
  local padding_top = (win_dim.pixel_height - tab_dim.pixel_height) / 2
  local new_padding = {
    left = padding_left,
    right = 0,
    top = padding_top,
    bottom = 0,
  }
  if overrides.window_padding and new_padding.left == overrides.window_padding.left then
    return
  end
  overrides.window_padding = new_padding
  window:set_config_overrides(overrides)
end

wezterm.on('window-resized', center_content)
wezterm.on('window-config-reloaded', center_content)

return config
