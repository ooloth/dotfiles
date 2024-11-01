# Vimium-C

It's [not possible](https://github.com/gdh1995/vimium-c/issues/563) to sync Vimium-C's settings to a file, so as a workaround, here's a best-effort attempt to document the settings I've customized:

## Custom key mappings

```
map yy copyWindowInfo type="tab" format="[${title}](${url})"
map yl copyWindowInfo type="tab" format="${url}"
map <c-l> nextTab
map <c-h> previousTab
map <c-j> goForward
map <c-k> goBack
map <c-]> nextTab
map <c-[> previousTab
map L nextTab
map H previousTab
map J goForward
map K goBack
```
