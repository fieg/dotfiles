#!/usr/bin/env bash

# Exit if any subcommand or pipeline returns a non-zero status
#set -e

DOTDIR=$HOME/.dotfiles

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

  user 'What is your github author name?' </dev/tty
  read git_authorname
  user 'What is your github author email?' </dev/tty
  read git_authoremail

  sed -e "s/AUTHORNAME/$git_authorname/g" -e "s/AUTHOREMAIL/$git_authoremail/g" -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" $DOTDIR/formulas/git/.gitconfig.local.template > $DOTDIR/formulas/git/.gitconfig.local
}

setup_brew_api_token () {
  if [[ -z "${HOMEBREW_GITHUB_API_TOKEN}" ]]; then
    info 'setup brew api token'

    user 'Enter HOMEBREW_GITHUB_API_TOKEN' </dev/tty
    read brew_api_token
    export HOMEBREW_GITHUB_API_TOKEN="$brew_api_token"

    test -f $DOTDIR/formulas/homebrew/env.local.zsh || sed -e "s/BREWTOKEN/$brew_api_token/g" $DOTDIR/formulas/homebrew/env.local.template > $DOTDIR/formulas/homebrew/env.local.zsh
  fi
}

install_brew () {
  info 'install homebrew'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  eval "$(/opt/homebrew/bin/brew shellenv)"
}

install_dotfiles () {
  info 'install dotfiles'
  /usr/bin/env git clone https://github.com/fieg/dotfiles.git $DOTDIR
}

update_dotfiles () {
  info 'update dotfiles'
  pushd $DOTDIR > /dev/null 2>&1
  git stash
  if git pull origin master
  then
    git stash apply
  fi
  popd > /dev/null 2>&1
}

install_pure_prompt () {
  brew install pure

  # see https://github.com/sindresorhus/pure/issues/584
  pushd $(brew --prefix)/share/zsh/site-functions > /dev/null 2>&1
  ln -sf $(brew --prefix)/lib/node_modules/pure-prompt/async.zsh async
  ln -sf $(brew --prefix)/lib/node_modules/pure-prompt/pure.zsh prompt_pure_setup
  popd > /dev/null 2>&1
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

# Clone dotfiles
( (test -d $DOTDIR && update_dotfiles) || install_dotfiles) && success 'dotfiles'

# Git config
(test -f $DOTDIR/formulas/git/.gitconfig.local || setup_gitconfig) && success 'gitconfig'

# Ask for the administrator password upfront
user "I need you to enter your sudo password so I can install some things:"
sudo -v || fail 'sudo required'

# Keep-alive: update existing sudo time stamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Homebrew
(test $(which brew) || install_brew) && success 'homebrew'

# Install apps
setup_brew_api_token

pushd $DOTDIR > /dev/null 2>&1
brew bundle
popd > /dev/null 2>&1

# set zsh as the user login shell
CURRENT_SHELL=$SHELL
EXPECTED_SHELL="$(brew --prefix)/bin/zsh"
if [ "$(uname -s)" == "Darwin" ]
then
  CURRENT_SHELL=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
fi
if [[ "$CURRENT_SHELL" != "$EXPECTED_SHELL" && -e $EXPECTED_SHELL ]]; then
  info "setting newer homebrew zsh ($EXPECTED_SHELL) as your shell"

  if [ "$(uname -s)" == "Darwin" ]
  then
    sudo dscl . -change /Users/$USER UserShell $CURRENT_SHELL $EXPECTED_SHELL > /dev/null 2>&1
  else
    if [ -f "$EXPECTED_SHELL" ]; then echo "$EXPECTED_SHELL" | sudo tee -a /etc/shells; fi
    chsh -s $EXPECTED_SHELL
  fi

  success 'shell changed'
fi


link_file () {
  local src="$1" dst="$HOME/${2:-$(basename $1)}"

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
    ln -s "$src" "$dst"
    success "$src → $dst"
  fi
}

overwrite_all=false backup_all=false skip_all=false

link_file "$DOTDIR/formulas/git/.gitconfig.local"
link_file "$DOTDIR/formulas/git/.gitconfig"
link_file "$DOTDIR/formulas/git/.gitignore"
test -d ~/.ssh || mkdir ~/.ssh
test -d ~/.ssh/conf.d || mkdir ~/.ssh/conf.d
link_file "$DOTDIR/formulas/ssh/config" ".ssh/config"
link_file "$DOTDIR/formulas/vim/.vimrc"
link_file "$DOTDIR/formulas/wget/.wgetrc"
link_file "$DOTDIR/formulas/bash/.inputrc"
link_file "$DOTDIR/formulas/zsh/.zshrc"
link_file "$DOTDIR/formulas/direnv/.direnvrc"
link_file "$DOTDIR/formulas/tmux/.tmux.conf"

if [[ "$(uname)" == "Darwin" ]]; then
  link_file "$DOTDIR/formulas/ssh/usekeychain-macos.conf" "~/.ssh/conf.d/usekeychain-macos.conf"
fi

# Install pure prompt
(brew ls --versions pure || install_pure_prompt) && success 'pure-prompt installed'

# Install terminal theme
#open "$DOTDIR/formulas/terminal/Snazzy.terminal"
info "To install Terminal theme, run:\n\n  open $DOTDIR/formulas/terminal/Snazzy.terminal"
info "To install Catppuccin theme, run:\n\n  open $DOTDIR/formulas/terminal/Catppuccin Mocha.terminal"


