#!/bin/bash

# Get current dir (so run this script from anywhere)

export DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Update dotfiles itself first

[ -d "$DOTFILES_DIR/.git" ] && git --work-tree="$DOTFILES_DIR" --git-dir="$DOTFILES_DIR/.git" pull origin master

# Bunch of symlinks
ln -sfv "$DOTFILES_DIR/.Xdefaults" ~
ln -sfv "$DOTFILES_DIR/.inputrc" ~
ln -sfv "$DOTFILES_DIR/.bashrc" ~
ln -sfv "$DOTFILES_DIR/.bash_profile" ~
ln -sfv "$DOTFILES_DIR/.cshrc" ~
#ln -sfv "$DOTFILES_DIR/runcom/.inputrc" ~
ln -sfv "$DOTFILES_DIR/git/.gitconfig" ~
ln -sfv "$DOTFILES_DIR/git/.gitignore_global" ~
ln -sfv "$DOTFILES_DIR/.emacs.d" ~
ln -sfv "$DOTFILES_DIR/.vimrc" ~
ln -sfv "$DOTFILES_DIR/.tmux.conf" ~
#ln -sfv "$DOTFILES_DIR/etc/mackup/.mackup.cfg" ~


#if [ "$(uname)" == "Darwin" -a -f "$DOTFILES_DIR/install/osx.sh" ]; then
#    source "$DOTFILES_DIR/install/osx.sh"
#fi
