# Visidata configuration file
# See: https://www.visidata.org/docs/customize/
# See: https://www.visidata.org/docs/api/commands

# TODO: disable basedpyright and ruff

options.color_default = "white on transparent"
options.default_width = 20

# FIXME: doesn't work yet
Sheet.addCommand("0", "go-leftmost")

Sheet.addCommand(
    "^D",
    "scroll-halfpage-down",
    "cursorDown(nScreenRows//2); sheet.topRowIndex += nScreenRows//2",
)
Sheet.addCommand(
    "^U",
    "scroll-halfpage-up",
    "cursorDown(nScreenRows//2); sheet.bottomRowIndex += nScreenRows//2",
)

# Enter insert mode with "i" instead of "e" to edit a cell
TableSheet.unbindkey("i")
TableSheet.bindkey("i", "edit-cell")
