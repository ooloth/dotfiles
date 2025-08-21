// see: https://github.com/brookhong/Surfingkeys/blob/master/docs/API.md
const { Clipboard, Hints, map, mapkey, removeSearchAlias, unmap, unmapAllExcept, vmap, vunmap } = api

// "linkHintCharacters": "asdfjklqwerzxc",
// "detectByCursorStyle": false,
// "openTab": "t"

map('gt', 'T') // go to a tab

map('<Ctrl-d>', 'd'), unmap('P') // scroll half page down ('d' still works too)
map('<Ctrl-h>', 'E'), unmap('E') // go one tab left
map('<Ctrl-i>', '<Alt-s>') // toggle Surfingkeys for current site
map('<Ctrl-j>', 'D'), unmap('D') // go forward in a tab's history
map('<Ctrl-k>', 'S'), unmap('S') // go back in a tab's history
map('<Ctrl-l>', 'R'), unmap('R') // go one tab right
map('<Ctrl-n>', 'F'), unmap('F') // go formard one visited tab
map('<Ctrl-p>', 'B'), unmap('B') // go back one visited tab
map('<Ctrl-u>', 'u'), unmap('e'), unmap('U') // scroll half page up ('u' still works too)

// TODO: reserve <Ctrl-f> for sending page to Feedbin
map('F', 'gf'), unmap('<Ctrl-f>'), unmap('C') // open link in non-active new tab

// NOTE: I use ctrl-m to merge all windows (in Chrome on Pro)

map('yl', 'yy') // copy page link with yl
mapkey('yy', 'Copy page link as markdown', () => {
  let url = document.URL
  let title = document.title
  Clipboard.write(`[${title}](${url})`)
})

// Allow opening VS Code Web on GitHub with '.'
unmap('.', /https:\/\/github\.com\/.*/i)

removeSearchAlias('b') // remove baidu
removeSearchAlias('d') // remove duckduckgo
removeSearchAlias('e') // remove wikipedia
removeSearchAlias('s') // remove stackoverflow
removeSearchAlias('w') // remove bing

// see: https://github.com/brookhong/Surfingkeys#properties-list
settings.blocklistPattern = undefined // regex for sites with Surfingkeys disabled
// settings.focusAfterClosed = 'last' // focus last tab after closing current tab
settings.focusFirstCandidate = true // focus first matched result in Omnibar
settings.hintAlign = 'left'
// settings.hintExplicit = true // wait for explicit input when there is only a single hint available
// settings.modeAfterYank = 'Normal' // after yanking text in Visual mode, switch to Normal mode
settings.richHintsForKeystroke = 100
settings.scrollStepSize = 150 // step size for each move by j/k
// settings.showModeStatus = true // always show mode
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
