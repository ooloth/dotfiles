# VisiData

## Testing config changes e2e via tmux

VisiData is a TUI, so use tmux to run it and verify changes.

### Start a test session

```bash
printf 'name,role,salary,active\nAlice,Engineer,120000,true\nBob,Manager,95000,false\n' > /tmp/vd_test.csv
tmux new-window -n "vd-test" "VD_CONFIG=$HOME/.config/visidata/config.py vd /tmp/vd_test.csv"
sleep 2
```

Always pass `VD_CONFIG` explicitly — the env var is required for the config to be picked up (see `shell.zsh`).

### Reload after a config change

```bash
tmux kill-window -t "vd-test" 2>/dev/null
tmux new-window -n "vd-test" "VD_CONFIG=$HOME/.config/visidata/config.py vd /tmp/vd_test.csv"
sleep 2
```

### Capture screen text

```bash
tmux capture-pane -t "vd-test" -p
```

### Capture and decode colors (escape sequences)

```bash
tmux capture-pane -t "vd-test" -e -p | python3 -c "
import sys
data = sys.stdin.read()
def decode(s):
    result = []
    i = 0
    while i < len(s):
        if s[i:i+2] == '\x1b[':
            j = i+2
            while j < len(s) and s[j] != 'm': j += 1
            codes = s[i+2:j].split(';')
            labels = []
            k = 0
            while k < len(codes):
                n = int(codes[k] or '0')
                if n==0: labels.append('RESET')
                elif n==1: labels.append('bold')
                elif 30<=n<=37: labels.append(['blk','red','grn','ylw','blu','mag','cyn','wht'][n-30])
                elif 40<=n<=47: labels.append('ON_'+['blk','red','grn','ylw','blu','mag','cyn','wht'][n-40])
                elif n==39: labels.append('fg:d')
                elif n==49: labels.append('on_d')
                elif n==90: labels.append('brt_blk')
                elif n==96: labels.append('brt_cyn')
                elif n==100: labels.append('ON_brt_blk')
                elif n==38 and k+2<len(codes) and codes[k+1]=='5': labels.append(f'FG256({codes[k+2]})'); k+=2
                elif n==48 and k+2<len(codes) and codes[k+1]=='5': labels.append(f'BG256({codes[k+2]})'); k+=2
                else: labels.append(f'({n})')
                k+=1
            result.append('['+','.join(labels)+']')
            i=j+1
        elif s[i]=='\n': result.append('\n'); i+=1
        else:
            j=i
            while j<len(s) and s[j]!='\x1b' and s[j]!='\n': j+=1
            t=s[i:j]; result.append(t if t.strip() else ''); i=j
    return ''.join(result)
for line in data.split('\n'):
    d = decode(line)
    if d.strip(): print(d)
"
```

### Trigger UI states for color testing

```bash
tmux send-keys -t "vd-test" " " ""       # open command palette
tmux send-keys -t "vd-test" "Tab" ""     # select first palette item (shows color_menu_spec)
tmux send-keys -t "vd-test" "Escape" ""  # close palette/menu
tmux send-keys -t "vd-test" "i" ""       # edit current cell (shows color_edit_cell)
```

### Color format reference

Values follow the pattern `"[modifiers] [fg] on [bg]"`:
- Modifiers: `bold`, `underline`, `reverse`, `italic`
- Named ANSI colors: `black red green yellow blue magenta cyan white`
- Numbered colors: `8` (Surface2), `11` (Peach), `12` (Lavender), `13` (Mauve), `14` (Sky)
- Use `transparent` as `bg` to inherit the terminal background

Catppuccin Mocha ANSI mapping (assumes terminal uses Catppuccin Mocha palette):

```
black=Surface1  red=Red      green=Green  yellow=Yellow  blue=Blue
magenta=Pink    cyan=Teal    white=Subtext1
8=Surface2      11=Peach     12=Lavender  13=Mauve       14=Sky
```

The option that controls the **selected item** in the command palette is `color_menu_spec`, not
`color_highlight_status`. The palette selected item is rendered in `cmdpalette.py` using
`colors.color_menu_spec` directly.
