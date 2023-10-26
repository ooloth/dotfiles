# My dotfiles

It dawned on me to make sure I don't lose these!

## Disclaimer

The settings here reflect my personal preferences, so...expect lots of changes and experiments. Unless you love surprises, I highly recommend you fork and customize this repo before using it.

## Prerequisites

1. Connect to the internet

2. Open System Preferences and sign into iCloud (which will sign you into the App Store for `mas`)

3. Open Terminal.app (you'll probably want to increase the font size)

4. Install Apple's command line tools:

```sh
xcode-select --install
```

5. Update your Mac's software (your Mac will automatically restart if necessary):

```sh
sudo softwareupdate --install --all --restart
```

6. Repeat (5) until everything is up to date

## Installation

To set up your Mac, run the following command:

```sh
curl -s https://raw.githubusercontent.com/ooloth/dotfiles/master/setup.sh | zsh
```

## Inspiration

- [How to make your Dotfile management a painless affair](https://www.freecodecamp.org/news/dive-into-dotfiles-part-2-6321b4a73608/)
- [Nick Nisi's dotfiles](https://github.com/nicknisi/dotfiles)
