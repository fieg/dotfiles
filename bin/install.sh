#!/bin/bash

# Exit if any subcommand or pipeline returns a non-zero status
set -e

info () {
  printf "\r\033[0;34m❯\033[0m $1\n"
}

success () {
  printf "\r\033[0;32m❯\033[0m $1\n"
  #printf "\e[0;32m  [✔] $1\e[0m\n"
}

user () {
 printf "\r\033[0;33m❯\033[0m $1\n"
}

fail () {
  printf "\r\033[0;33m❯\033[0m $1\n"
  exit
}

setup_gitconfig () {
  info 'setup gitconfig'

  git_credential='cache'
  if [ "$(uname -s)" == "Darwin" ]
  then
    git_credential='osxkeychain'
  fi

  user 'What is your github author name?'
  read -e git_authorname
  user 'What is your github author email?'
  read -e git_authoremail

  sed -e "s/AUTHORNAME/$git_authorname/g" -e "s/AUTHOREMAIL/$git_authoremail/g" -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" formulas/git/.gitconfig.local.template > formulas/git/.gitconfig.local
}

instal_brew () {
  info 'install homebrew'
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

install_dotfiles () {
  info 'install dotfiles'
  /usr/bin/env git clone https://github.com/fieg/dotfiles.git ~/.dotfiles
}

# install command line tools so we have git
# loops while we don't have the tools installed
xcode-select -p > /dev/null 2>&1
if [ $? == 2 ]
then
  info 'install command line developer tools'
  while true; do
    xcode-select --install > /dev/null 2>&1
    sleep 5
    xcode-select -p > /dev/null 2>&1
    [ $? == 2 ] || break
  done
fi
success 'developer tools'

# Prerequisites
(test $(which git) || fail 'git not installed') && success 'git'
(test $(which ruby) || fail 'ruby not installed') && success 'ruby'

# Git config
(test -f formulas/git/.gitconfig.local || setup_gitconfig) && success 'gitconfig'

# Clone dotfiles
(test -d ~/.dotfiles || install_dotfiles) && success 'dotfiles'

# Homebrew
(test $(which brew) || install_brew) && success 'homebrew'

# Install apps
brew bundle

# Ask for the administrator password upfront
user "I need you to enter your sudo password so I can install some things:"
sudo -v

# Keep-alive: update existing sudo time stamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# set zsh as the user login shell
CURRENTSHELL=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
if [[ "$CURRENTSHELL" != "/usr/local/bin/zsh" ]]; then
  info "setting newer homebrew zsh (/usr/local/bin/zsh) as your shell"
  # sudo bash -c 'echo "/usr/local/bin/zsh" >> /etc/shells'
  # chsh -s /usr/local/bin/zsh
  sudo dscl . -change /Users/$USER UserShell $SHELL /usr/local/bin/zsh > /dev/null 2>&1
fi
success 'shell changed'

link_file () {
  local src="$(pwd)/$1" dst="$HOME/${2:-$(basename $1)}"

  local overwrite= backup= skip=
  local action=

  if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]
  then

    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]
    then

      local currentSrc="$(readlink $dst)"

      if [ "$currentSrc" == "$src" ]
      then

        skip=true;

      else

        user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -n 1 action

        case "$action" in
          o )
            overwrite=true;;
          O )
            overwrite_all=true;;
          b )
            backup=true;;
          B )
            backup_all=true;;
          s )
            skip=true;;
          S )
            skip_all=true;;
          * )
            exit 1;;
        esac

      fi

    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == "true" ]
    then
      rm -rf "$dst"
      success "removed $dst"
    fi

    if [ "$backup" == "true" ]
    then
      mv "$dst" "${dst}.backup"
      success "moved $dst to ${dst}.backup"
    fi

    if [ "$skip" == "true" ]
    then
      success "skipped $src"
    fi
  fi

  if [ "$skip" != "true" ]  # "false" or empty
  then
    ln -s "$1" "$2"
    success "$src → $dst"
  fi
}

overwrite_all=false backup_all=false skip_all=false

link_file "formulas/git/.gitconfig.local"
link_file "formulas/git/.gitconfig"
link_file "formulas/git/.gitignore"
link_file "formulas/ssh/config" ".ssh/config"
link_file "formulas/vim/.vimrc"
link_file "formulas/wget/.wgetrc"
link_file "formulas/bash/.inputrc"
link_file "formulas/zsh/.zshrc"
