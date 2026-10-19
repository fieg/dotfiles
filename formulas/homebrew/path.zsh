# On macOS /home is an autofs mount backed by the directory service, so probing
# a non-existent /home/linuxbrew path blocks on a lookup for ~10-120ms. compinit
# does that on every autoload, which added minutes to shell startup
typeset -U path fpath

if [[ $OSTYPE == darwin* ]]; then
  for brew_prefix in /opt/homebrew /usr/local; do
    [[ -x $brew_prefix/bin/brew ]] && break
  done
else
  brew_prefix=/home/linuxbrew/.linuxbrew
fi

if [[ -n $brew_prefix && -d $brew_prefix/bin ]]; then
  path=($brew_prefix/bin $brew_prefix/sbin $path)
  fpath=($brew_prefix/share/zsh/site-functions $fpath)
fi
unset brew_prefix