export GPG_TTY="$(tty)"
export TLDR_COLOR_BLANK="blue"
export TLDR_COLOR_DESCRIPTION="green"
export TLDR_COLOR_PARAMETER="blue"
export ZSH_AUTOSUGGEST_USE_ASYNC=true
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#a8a8a8,underline"
export KEYTIMEOUT=5
export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}

setopt autocd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'
alias -- -='cd -'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
# Allows alias after sudo. If the last character of the alias value is a space
# or tab character, then the next command word following the alias is also
# checked for alias expansion.
# http://www.gnu.org/software/bash/manual/bashref.html#Aliases
alias sudo="sudo "
alias _="sudo"
