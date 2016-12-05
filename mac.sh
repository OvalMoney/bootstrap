#!/bin/bash

# Turn your mac into an Oval development machine :)

BASH_PROFILE="$HOME/.bash_profile"

if [ ! -f "$BASH_PROFILE" ]; then
  touch "$BASH_PROFILE"
fi

append_to_bash_profile() {
  local text="$1"
  local skip_new_line="${2:-0}"

  if ! grep -Fqs "$text" "$BASH_PROFILE"; then
    if [ "$skip_new_line" -eq 1 ]; then
      printf "%s\n" "$text" >> "$BASH_PROFILE"
    else
      printf "\n%s\n" "$text" >> "$BASH_PROFILE"
    fi
  fi
}

echo "Setting locale to en_US.UTF-8 ..."
append_to_bash_profile '# set locale'
append_to_bash_profile 'export LC_ALL=en_US.UTF-8' 1
append_to_bash_profile 'export LANG=en_US.UTF-8' 1

echo "Installing Xcode CLI tools ..."
touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
PROD=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')
softwareupdate -i "$PROD" -v

HOMEBREW_PREFIX="/usr/local"

if [ -d "$HOMEBREW_PREFIX" ]; then
  if ! [ -r "$HOMEBREW_PREFIX" ]; then
    sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
  fi
else
  sudo mkdir "$HOMEBREW_PREFIX"
  sudo chflags norestricted "$HOMEBREW_PREFIX"
  sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
fi

if ! command -v brew >/dev/null; then
  echo "Installing Homebrew ..."
  curl -fsS 'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby
  append_to_bash_profile '# recommended by brew doctor'
  append_to_bash_profile 'export PATH="/usr/local/bin:$PATH"' 1
  append_to_bash_profile 'export PATH="/usr/local/sbin:$PATH"' 1
  export PATH="/usr/local/sbin:/usr/local/bin:$PATH"
fi

echo "Updating Homebrew formulae ..."
brew update
brew bundle --file=- <<EOF
# Unix
brew "wget"
brew "openssl"
# Heroku
brew "heroku-toolbelt"
# Python
brew "python"
brew "python3"
brew "pyenv"
brew "pyenv-virtualenv"
# Databases
brew "mysql"
EOF

echo "Configuring pyenv ..."
append_to_bash_profile "# pyenv"
append_to_bash_profile 'if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi' 1
append_to_bash_profile 'if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi' 1
