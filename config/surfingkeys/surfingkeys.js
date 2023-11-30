// see: https://github.com/brookhong/Surfingkeys/blob/master/docs/API.md
const { Clipboard, Hints, map, mapkey, removeSearchAlias, unmap, unmapAllExcept, vmap, vunmap } = api

// "linkHintCharacters": "asdfjklqwerzxc",
// "detectByCursorStyle": false,
// "openTab": "t"

map('<Ctrl-i>', '<Alt-s>') // toggle Surfingkeys for current site

map('<Ctrl-h>', 'E') // go one tab left
unmap('E')
map('<Ctrl-l>', 'R') // go one tab right
unmap('R')

map('<Ctrl-k>', 'S') // go back in a tab's history
unmap('S')
map('<Ctrl-j>', 'D') // go forward in a tab's history
unmap('D')

map('<Ctrl-d>', 'd') // scroll half page down
// unmap('d')
unmap('P')
map('<Ctrl-u>', 'e') // scroll half page up
unmap('e')
unmap('U')

map('<Ctrl-b>', 'B') // go back one tab
unmap('B')
map('<Ctrl-f>', 'F') // go formard one tab
unmap('F')

map('F', 'C') // open link in non-active new tab

map('gt', 'T')

map('yl', 'yy') // copy page link with yl

mapkey('yy', 'Copy page link as markdown', () => {
  let url = document.URL
  let title = document.title
  Clipboard.write(`[${title}](${url})`)
})

removeSearchAlias('b') // remove baidu
removeSearchAlias('d') // remove duckduckgo
removeSearchAlias('e') // remove wikipedia
removeSearchAlias('s') // remove stackoverflow
removeSearchAlias('w') // remove bing

// see: https://github.com/brookhong/Surfingkeys#properties-list
settings.blocklistPattern = undefined // regex for sites with Surfingkeys disabled
settings.enableEmojiInsertion = true // enable emoji insertion after ":" in insert mode
// settings.focusAfterClosed = 'last' // focus last tab after closing current tab
settings.focusFirstCandidate = true // focus first matched result in Omnibar
settings.hintAlign = 'left'
// settings.hintExplicit = true // wait for explicit input when there is only a single hint available
// settings.modeAfterYank = 'Normal' // after yanking text in Visual mode, switch to Normal mode
settings.richHintsForKeystroke = 100
settings.scrollStepSize = 150 // step size for each move by j/k
// settings.showModeStatus = true // always show mode
settings.startToShowEmoji = 0 // show emoji 0 chars after ":"
// settings.tabsMRUOrder = false // list opened tabs in order of most recently used
settings.tabsThreshold = 20 // choose tabs with omnibar when tabs exceed this number
settings.theme = `
.sk_theme {
  font-family: Input Sans Condensed, Charcoal, sans-serif;
  font-size: 10pt;
  background: #24272e;
  color: #abb2bf;
}
.sk_theme tbody {
    color: #fff;
}
.sk_theme input {
    color: #d0d0d0;
}
.sk_theme .url {
    color: #61afef;
}
.sk_theme .annotation {
    color: #56b6c2;
}
.sk_theme .omnibar_highlight {
    color: #528bff;
}
.sk_theme .omnibar_timestamp {
    color: #e5c07b;
}
.sk_theme .omnibar_visitcount {
    color: #98c379;
}
.sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
    background: #303030;
}
.sk_theme #sk_omnibarSearchResult ul li.focused {
    background: #3e4452;
}
#sk_status, #sk_find {
    font-size: 20pt;
}`
