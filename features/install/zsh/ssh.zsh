#!/usr/bin/env zsh

# This script...
#
# 1. Generates the SSH keys
# 2. Creates the SSH config file
# 3. Add the keys to the ssh-agent
# 4. Add the keys to Keychain

# Exit immediately if a command exits with a non-zero status to avoid acting on bad data
set -e

DOTFILES="$HOME/Repos/ooloth/dotfiles"


info "🔑 Installing SSH key pair"

ssh_dir="$HOME/.ssh"
private_key_path="$ssh_dir/id_rsa"
public_key_path="$ssh_dir/id_rsa.pub"

#####################
# GENERATE SSH KEYS #
#####################

printf "\n🔍 Checking for existing SSH keys\n"

ssh_key_pair_found() {
  [[ -s "$private_key_path" && -s "$public_key_path" ]]
  return $? # Return the exit status of the test command
}

if ssh_key_pair_found; then
  printf "\n✅ SSH key pair found.\n"
  return_or_exit 0
else
  printf "\n👎 No SSH key pair found.\n"
  printf "\n✨ Generating a new 2048-bit RSA SSH public/private key pair.\n"

  # Generate a 2048-bit RSA SSH key pair
  # -q makes the process quiet (suppresses warnings and prompts)
  # -N '' sets an empty passphrase for the key
  # <<< ""$'\n'"y" automatically answers "yes" to the prompt asking to overwrite the existing key
  # 2>&1 >/dev/null redirects standard output and standard error to /dev/null, effectively silencing all output
  # https://security.stackexchange.com/a/23385
  # https://stackoverflow.com/a/43235320
  ssh-keygen -q -t rsa -b 2048 -N '' <<<""$'\n'"y" 2>&1 >/dev/null

  # Check if the key pair was generated successfully
  if ssh_key_pair_found; then
    printf "\n✅ SSH key pair generated successfully.\n"
  else
    printf "\n❌ Failed to generate SSH key pair.\n"
    return 1
  fi
fi

##########################
# CREATE SSH CONFIG FILE #
##########################

printf "\n📄 Creating SSH config file"

ssh_config="$ssh_dir/config"

# Use SSH config settings that automatically load keys in ssh-agent and store passphrases in Keychain
# https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
settings=("Host *"
  "  AddKeysToAgent yes"
  "  UseKeychain yes"
  "  IdentityFile $private_key_path")

write_settings() {
  mkdir -p "$ssh_dir"
  printf "%s\n" "${settings[@]}" >"$ssh_config"
}

if [ -f "$ssh_config" ]; then
  printf "\n✅ SSH config file found. Checking contents...\n"

  all_settings_found=true
  for setting in "${settings[@]}"; do
    if ! grep -Fxq "$setting" "$ssh_config"; then
      printf "\n❌ SSH config file does not contain the expected setting: %s\n" "$setting"
      all_settings_found=false
    fi
  done

  if $all_settings_found; then
    printf "\n✅ SSH config file contains all the expected settings.\n"
  else
    printf "\n❌ SSH config file does not contain all the expected settings. Updating...\n"
    write_settings
  fi
else
  printf "SSH config file does not exist. Creating...\n"
  write_settings
fi

#####################################################
# ADD KEY TO SSH-AGENT + ITS PASSPHRASE TO KEYCHAIN #
#####################################################

printf "\n🔑 Adding SSH key pair to ssh-agent and Keychain\n"

# https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent
if ! eval "$(ssh-agent -s)"; then
  printf "\n❌ Failed to start SSH agent.\n"
  exit 1
fi
printf "\n✅ SSH agent started successfully.\n"

# Add SSH private key to ssh-agent and store the passphrase in Keychain
if ! ssh-add -K "$private_key_path"; then
  printf "\n❌ Failed to add SSH key at %s.\n" "$private_key_path"
  exit 1
fi
printf "\n✅ SSH key added successfully at %s.\n" "$private_key_path"

printf "\n🚀 Done configuring your SSH key pair.\n"
