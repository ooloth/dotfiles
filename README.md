# My dotfiles

It dawned on me that I should make sure I don't lose these!

## Setup

Locally, these files live outside my home folder with my other project files. I symlinked them to the corresponding files in my home directory by navigating to my home directory and running the following commands once:

```sh
ln -sfv ~/Sites/projects/dotfiles/.zshrc ~
ln -sfv ~/Sites/projects/dotfiles/.vimrc ~
ln -sfv ~/Sites/projects/dotfiles/alacritty.yml ~/.config/alacritty/alacritty.yml
```

Now, changes to these files are synced to the home directory automatically.

## Disclaimer

The settings here are based purely on my personal preferences and I'm doing this for fun, so...expect lots of changes and experimenting. Unless you love surprises, you'll probably want to fork this repo before using them.
