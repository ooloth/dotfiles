require('lualine').setup({
	options = {
    icons_enabled = true,
    -- theme = 'everforest',
    -- theme = 'gruvbox_material',
    theme = 'nord',
    -- theme = 'palenight',
    component_separators = {'', ''},
    section_separators = {'', ''},
    disabled_filetypes = {}
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch'},
    lualine_c = {{
      'filename',
      file_status = true, -- displays file status (readonly status, modified status)
      path = 1 -- 0 = just filename, 1 = relative path, 2 = absolute path
    }},
    lualine_x = {{
      'diff',
      colored = true, -- displays diff status in color if set to true
      -- all colors are in format #rrggbb
      color_added = nil, -- changes diff's added foreground color
      color_modified = nil, -- changes diff's modified foreground color
      color_removed = nil, -- changes diff's removed foreground color
      symbols = {added = '+', modified = '~', removed = '-'} -- changes diff symbols
    },
      {
      'diagnostics',
      sources = { 'nvim_lsp' },
      -- displays diagnostics from defined severity
      -- sections = {'error', 'warn', 'info', 'hint'},
      -- all colors are in format #rrggbb
      color_error = '#ffffff',
      color_warn = '#ffffff',
      color_info = '#ffffff',
      color_hint = '#ffffff',
      symbols = { error = '🐞 ', warn = '🚧 ', info = 'ℹ️  ', hint = '💡 '}
    }},
    lualine_y = {'filetype'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {{
     'filename',
      file_status = true, -- displays file status (readonly status, modified status)
      path = 1 -- 0 = just filename, 1 = relative path, 2 = absolute path
    }},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {'quickfix', 'fugitive', 'nvim-tree'}
})
