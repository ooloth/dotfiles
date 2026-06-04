# Visidata configuration file
# See: https://www.visidata.org/docs/customize/
# See: https://www.visidata.org/docs/api/commands

# ruff: noqa
# type: ignore


###########
# OPTIONS #
###########

options.default_width = 20
options.visidata_dir = "~/.config/visidata/"

##########
# COLORS #
##########

# Catppuccin Mocha — requires terminal configured with Catppuccin Mocha ANSI palette.
# ANSI name → Catppuccin color:
#   black=Surface1  red=Red      green=Green  yellow=Yellow  blue=Blue
#   magenta=Pink    cyan=Teal    white=Subtext1
#   8=Surface2      11=Peach     12=Lavender  13=Mauve       14=Sky

# Base
options.color_default = "white on transparent"
options.color_default_hdr = "bold blue on transparent"
options.color_bottom_hdr = "underline blue on transparent"
options.color_column_sep = "8 on transparent"

# Cursor
options.color_current_row = "bold white on black"
options.color_current_col = "bold blue on black"
options.color_current_hdr = "bold blue reverse"
options.color_current_cell = "bold black on blue"

# Selection & keys
options.color_selected_row = "bold yellow on transparent"
options.color_key_col = "bold cyan"

# Status bar
options.color_status = "bold white on black"
options.color_active_status = "bold black on blue"
options.color_inactive_status = "8 on black"
options.color_highlight_status = "bold black on green"
options.color_keystrokes = "bold white on black"

# Editing
options.color_edit_cell = "bold black on yellow"

# Messages
options.color_error = "bold red"
options.color_warning = "bold 11"
options.color_working = "bold green"

# Pending changes
options.color_add_pending = "bold green"
options.color_change_pending = "bold 11"
options.color_delete_pending = "bold red"

# Notes
options.color_note_pending = "bold green"
options.color_note_type = "13"
options.color_note_row = "yellow"

# Menus & palette
options.color_menu = "black on blue"
options.color_menu_active = "black on yellow"
options.color_menu_spec = "black on green"
options.color_menu_help = "italic black on blue"
options.color_cmdpalette = "black on cyan"
options.color_sidebar = "black on blue"
options.color_sidebar_title = "bold black on yellow"

# Misc
options.color_aggregator = "bold white on black"
options.color_heading = "bold black on yellow"
options.color_match = "bold red"
options.color_graph_axis = "bold white"
options.color_graph_hidden = "8 on transparent"

#############################
# KEYBINDS FOR NEW COMMANDS #
#############################

# If a command already exists and I'm just changing the keybind, use "bindkey()". If it doesn't
# exist yet, use "addCommand" to define the keybind, command name and exec string.

BaseSheet.addCommand(
    "Ctrl+D",
    "scroll-halfpage-down",
    "cursorDown(nScreenRows//2); sheet.topRowIndex += nScreenRows//2",
)
BaseSheet.addCommand(
    "Ctrl+U",
    "scroll-halfpage-up",
    "cursorDown(-nScreenRows//2); sheet.topRowIndex -= nScreenRows//2",
)

##################################
# KEYBINDS FOR EXISTING COMMANDS #
##################################

BaseSheet.bindkey("0", "go-leftmost")

# Enter insert mode with "i" instead of "e" to edit a cell
TableSheet.unbindkey("i")
TableSheet.bindkey("i", "edit-cell")
