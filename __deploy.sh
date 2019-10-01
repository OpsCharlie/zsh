#!/bin/bash

P=$1
DIR=$(dirname $(readlink -f $0))

if [ -z $P ]; then
    echo Copying files to homedir
    mv ~/.zshrc ~/.zshrc.bak
    mv ~/.zsh_aliases ~/.zsh_aliases.bak
    mv ~/.dircolors ~/.dircolors.bak
    cp $DIR/zshrc ~/.zshrc
    cp $DIR/zsh_aliases ~/.zsh_aliases
    cp $DIR/dircolors ~/.dircolors
    exit $?
fi


if [ "$(expr match "$P" '.*\(:\)')" = ":" ]; then
    echo "Usage:"
    echo "$0               to deploy local"
    echo "$0 user@host     to deploy remote"
    exit 1
fi

ssh $P "mv ~/.zshrc ~/.zshrc.bak;\
mv ~/.zsh_aliases ~/.zsh_aliases.bak;\
mv ~/.dircolors ~/.dircolors.bak"

sftp $P << EOF
put zshrc       .zshrc
put zsh_aliases .zsh_aliases
put dircolors       .dircolors
EOF
