# Visidata configuration file
# See: https://www.visidata.org/docs/customize/
# See: https://www.visidata.org/docs/api/commands

# ruff: noqa
# type: ignore


###########
# OPTIONS #
###########

options.color_default = "white on transparent"
options.default_width = 20
options.visidata_dir = "~/.config/visidata/"

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
