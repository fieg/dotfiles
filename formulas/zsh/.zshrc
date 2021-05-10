# shortcut to this dotfiles path is $ZSH
export DOTDIR=$HOME/.dotfiles

# all of our zsh files
typeset -U config_files
config_files=($DOTDIR/**/*.zsh)

export PATH="/usr/local/bin:/usr/local/sbin:$HOME/bin:/usr/bin:/bin:/usr/sbin:/sbin:$DOTDIR/formulas/bin"

# load the path files
for file in ${(M)config_files:#*/path.zsh}
do
  source $file
done

# load everything but the path and completion files
for file in ${${config_files:#*/path.zsh}:#*/completion.zsh}
do
  source $file
done

# initialize autocomplete here, otherwise functions won't be loaded
autoload -U compinit
compinit

# Bash style word selection, allows to delete words up to directory separator
autoload -U select-word-style
select-word-style bash

# load every completion after autocomplete loads
for file in ${(M)config_files:#*/completion.zsh}
do
  source $file
done

unset config_files

setopt autocd       # change directory just by typing its name
setopt extendedglob # enables additional globbing patterns

autoload -U promptinit; promptinit
prompt pure

[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh
[ -f $(brew --prefix)/etc/profile.d/autojump.sh ] && . $(brew --prefix)/etc/profile.d/autojump.sh
[ -d $(brew --prefix)/share/zsh-syntax-highlighting ] && . $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -d $(brew --prefix)/share/zsh-autosuggestions ] && . $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

eval "$(direnv hook zsh)"
