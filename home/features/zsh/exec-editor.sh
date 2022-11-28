#!/bin/bash

if which emacsclient > /dev/null; then
  emacsclient -s ~/local/run/emacs/misc -t -a vim $*
elif which vim > /dev/null
     vim $*
else
  vi $*
fi

