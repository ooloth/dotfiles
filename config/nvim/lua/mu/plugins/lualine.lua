local status, lualine = pcall(require, "lualine") -- import lualine plugin safely
if not status then
  return
end

local lualine_nightfly = require("lualine.themes.nightfly") -- get lualine nightfly theme

-- new colors for theme
local new_colors = {
  blue = "#65D1FF",
  green = "#3EFFDC",
  violet = "#FF61EF",
  yellow = "#FFDA7B",
  black = "#000000",
}

-- change nightfly theme colors
lualine_nightfly.normal.a.bg = new_colors.blue
lualine_nightfly.insert.a.bg = new_colors.green
lualine_nightfly.visual.a.bg = new_colors.violet
lualine_nightfly.command = {
  a = {
    gui = "bold",
    bg = new_colors.yellow,
    fg = new_colors.black, 
  },
}

-- configure lualine with modified theme
lualine.setup({
  options = {
    theme = lualine_nightfly,
  },
})
