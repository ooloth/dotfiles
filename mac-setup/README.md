# mac-setup

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

To set up your Mac, run this command:

```sh
curl --remote-name https://raw.githubusercontent.com/ooloth/mac-setup/master/setup && sh setup 2>&1 | tee ~/setup.log
```

You'll need to enter your `sudo` password multiple times during the process, so get comfortable. ☕

## What does it do?

- TODO

## Post-install tasks

After running `setup`, you'll need to finish by setting up a few things manually:

1. Restart your Mac
2. Go to System Preferences > Security & Privacy > Privacy > Developer Tools and add your terminal
   apps with a checkmark next to each so your Mac will let you open apps installed with Homebrew.
3. Confirm you can connect to GitHub via SSH by running `ssh -T git@github.com`. If you see
   "Permission denied (public key).", the public key you entered in GitHub doesn't match the private
   key on your Mac. Try adding it again, making sure to include everything in your `~/.ssh/id_rsa`
   file.
4. Complete the post-install tasks from dotfiles README.
5. Manually set any remaining app settings and macOS keyboard shortcuts (see example list below)

## macOS Keyboard Shortcuts

I like to manually adjust the following settings that weren't set automatically:

- **Rectangle:** enable "Launch on login" + "Check for updates automatically"

## macOS Keyboard Shortcuts

I like to customize the following keyboard shortcuts:

- **Alfred:** `⌘Space`
- **Things:** `⌃Space`
