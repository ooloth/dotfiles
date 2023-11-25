// see: https://github.com/brookhong/Surfingkeys/blob/master/docs/API.md
const { Clipboard, Hints, map, mapkey, unmap, unmapAllExcept, vmap, vunmap } = api

mapkey('<Ctrl-y>', 'Copy page link as markdown', () => {
  let url = document.URL
  let title = document.title
  Clipboard.write(`[${title}](${url})`)
})

// see: https://github.com/brookhong/Surfingkeys/blob/master/docs/API.md#map
map('gt', 'T')
map('<Ctrl-h>', 'E') // go one tab left
unmap('E')
map('<Ctrl-l>', 'R') // go one tab right
unmap('R')

map('<Ctrl-k>', 'S') // go back in history
unmap('S')
map('<Ctrl-j>', 'D') // go forward in history
unmap('D')

// {
//     "disabledSearchAliases": {
//         "b": "baidu",
//         "d": "duckduckgo",
//         "e": "wikipedia",
//         "s": "stackoverflow",
//         "w": "bing"
//     },
// }

settings.hintAlign = 'left'
// set theme
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
