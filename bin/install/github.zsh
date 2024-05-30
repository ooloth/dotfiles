#!/usr/bin/env zsh

# This script handles adding the SSH key generated by install/ssh.zsh to GitHub
# and verifying the SSH connection to GitHub is working.

set -e

source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🔑 Adding SSH key pair to GitHub"

PRIVATE_KEY="$HOME/.ssh/id_rsa"
PUBLIC_KEY="$PRIVATE_KEY.pub"

i_can_connect_to_github_via_ssh() {
  ssh -T git@github.com >/dev/null 2>&1
}

if i_can_connect_to_github_via_ssh; then
  printf "\n✅ You can already connect to GitHub via SSH.\n"
  return
fi

if [[ ! -s "$PRIVATE_KEY" || ! -s "$PUBLIC_KEY" ]]; then
  printf "\n❌ SSH keys not found. Generating a new key pair...\n"
  source "$HOME/Repos/ooloth/dotfiles/install/ssh.zsh"

  # Check if the key pair was added to the ssh-agent
  if ! ssh-add -l >/dev/null; then
    printf "\n❌ Failed to add SSH key to ssh-agent. Please try again.\n"
    exit 1
  fi
fi

printf "\nYour turn!"
printf "\nPlease visit https://github.com/settings/ssh/new now and add the SSH key that has been copied to your clipboard to your GitHub account."
pbcopy < "$PUBLIC_KEY"
printf "\n⚠️ Actually go do this! This step is required before you'll be able to clone repos via SSH.\n"

vared -p "All set? (y/N)" -c gitHubKeyAdded

if [[ ! "$gitHubKeyAdded" == 'y' ]]; then
  printf "\nYou have chosen...poorly.\n"
  return 0 || exit 0
else
  printf "\nExcellent!\n"
fi

printf "\n🧪 Verifying you can now connect to GitHub via SSH...\n"

if i_can_connect_to_github_via_ssh; then
  printf "\n✅ SSH key was added to GitHub successfully.\n"
else
  printf "\n❌ Failed to add SSH key to GitHub. Please try again.\n"
  exit 1
fi

printf "\n🚀 Done adding your SSH key pair to GitHub."

#############################################
# CONVERT DOTFILES REMOTE FROM HTTPS TO SSH #
#############################################

# Use a subshell to change the directory to avoid impacting the parent script
(
  # Navigate to the dotfiles repository directory
  cd "$HOME/dotfiles"

  # Get the current remote URL
  REMOTE_URL=$(git config --get remote.origin.url)

  # Check if the remote URL uses the HTTPS protocol
  if [[ "$REMOTE_URL" == https://github.com/* ]]; then
    # Convert the HTTPS URL to an SSH URL
    printf "\n🔗 Converting the dotfiles remote URL from HTTPS to SSH\n"
    SSH_URL="git@github.com:${REMOTE_URL#https://github.com/}.git"

    # Set the new remote URL
    # see: https://stackoverflow.com/questions/55246165/how-to-ssh-a-git-repository-after-already-cloned-with-https
    git remote set-url origin "$SSH_URL"
  fi

  printf "\nTODO: verify dotfiles remote URL has been updated to use SSH...\n"
)

printf "\n✅ Dotfiles remote URL has been updated to use SSH\n"