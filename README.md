# My dotfiles

It dawned on me that I should make sure I don't lose these!

## Setup

Locally, these files live outside my home folder with my other project files. I symlinked them to the corresponding files in my home directory by running the following commands once:

```sh
ln -sfv $HOME/Sites/projects/dotfiles/.config/alacritty/alacritty.yml $HOME/.config/alacritty/alacritty.yml
ln -sfv $HOME/Sites/projects/dotfiles/.config/git/ignore $HOME/.config/git/ignore
ln -sfv $HOME/Sites/projects/dotfiles/.config/nvim/init.vim $HOME/.config/nvim/init.vim
ln -sfv $HOME/Sites/projects/dotfiles/.config/nvim/mappings.vim $HOME/.config/nvim/mappings.vim
ln -sfv $HOME/Sites/projects/dotfiles/.config/nvim/plugins.vim $HOME/.config/nvim/plugins.vim
ln -sfv $HOME/Sites/projects/dotfiles/.config/nvim/settings.vim $HOME/.config/nvim/settings.vim
ln -sfv $HOME/Sites/projects/dotfiles/.config/nvim/snippets/javascript.snippets $HOME/.config/nvim/snippets/javascript.snippets
ln -sfv $HOME/Sites/projects/dotfiles/.config/.secrets $HOME/.config/.secrets
ln -sfv $HOME/Sites/projects/dotfiles/.config/vifm/vifmrc $HOME/.config/vifm/vifmrc
ln -sfv $HOME/Sites/projects/dotfiles/.gitconfig $HOME
ln -sfv $HOME/Sites/projects/dotfiles/.tmux.conf $HOME
ln -sfv $HOME/Sites/projects/dotfiles/.zshrc $HOME
```

Now, updates to these files will be synced to the home directory automatically.

## Disclaimer

The settings here are based purely on my personal preferences and I'm doing this for fun, so...expect lots of changes and experimenting. Unless you love surprises, you'll probably want to fork this repo before using them.

## Inspiration

- [How to make your Dotfile management a painless affair](https://www.freecodecamp.org/news/dive-into-dotfiles-part-2-6321b4a73608/)
