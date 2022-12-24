if which emacsclient > /dev/null; then
  emacsclient -t -a vim $*
elif which vim > /dev/null; then
     vim $*
else
  vi $*
fi

