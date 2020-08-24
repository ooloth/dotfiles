# My dotfiles

It dawned on me that I should make sure I don't lose these!

## Disclaimer

The settings here are based purely on my personal preferences and I'm doing this for fun, so...expect lots of changes and experimenting. Unless you love surprises, you'll probably want to fork this repo before using them.

## Prerequisites

1. Install Apple's command line tools:

```sh
xcode-select --install
```

2. Update your Mac's software (your Mac will automatically restart if necessary):

```sh
sudo softwareupdate --install --all --restart
```

3. Repeat (2) until everything is up to date

## Installation

To set up your Mac with one command, run this command:

```sh
curl -s https://raw.githubusercontent.com/ooloth/dotfiles/master/install.sh | zsh -s all
```

To run only one part of the install setup, replace `all` with `backup`, `link` `git`, `homebrew`, `shell`, `terminfo` or `macos`.

## What does it do?

- TODO

## Post-install tasks

I'd like to automate the following steps as well (let me know if you know how), but for now you'll need to set up a few last things manually:

1. Restart your Mac
2. Go to System Preferences > Security & Privacy > Privacy > Developer Tools and add your terminal
   apps with a checkmark next to each so your Mac will let you open apps installed with Homebrew.
3. Confirm you can connect to GitHub via SSH by running `ssh -T git@github.com`. If you see
   "Permission denied (public key).", the public key you entered in GitHub doesn't match the private
   key on your Mac. Try adding it again, making sure to include everything in your `~/.ssh/id_rsa`
   file.
4. Manually set any remaining app settings and macOS keyboard shortcuts (see example list below)

## macOS Keyboard Shortcuts

I like to manually adjust the following settings that weren't set automatically:

- **Rectangle:** enable "Launch on login" + "Check for updates automatically"

## macOS Keyboard Shortcuts

I like to customize the following keyboard shortcuts:

- **Alfred:** `⌘Space`
- **Things:** `⌃Space`

## Inspiration

- [How to make your Dotfile management a painless affair](https://www.freecodecamp.org/news/dive-into-dotfiles-part-2-6321b4a73608/)
- [Nick Nisi's dotfiles](https://github.com/nicknisi/dotfiles)
