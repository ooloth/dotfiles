# dotfiles

Dawned on me I should probably make sure I don't lose these!

Locally, these files live outside my home folder (with my other project files). I simlinked them to the corresponding files in my home directory by running these commands once (from my home directory) so that the actual dotfiles will automatically stay in sync as I save changes:

```sh
ln -sfv ~/Sites/projects/dotfiles/.zshrc ~
ln -sfv ~/Sites/projects/dotfiles/.vimrc ~
ln -sfv ~/Sites/projects/dotfiles/alacritty.yml ~/.config/alacritty/alacritty.yml
```

I'm probably going to change these a lot, so unless you enjoy surprises, you may want to fork them before using them.
