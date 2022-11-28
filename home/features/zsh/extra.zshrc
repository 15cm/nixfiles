# Disable Ctrl-s which freezes the terminal
stty -ixon

# Enable editing current command in editors.
autoload edit-command-line
zle -N edit-command-line

# <tab> selection color
zstyle ':completion:*' menu select

# Fix backspace behavior after switching back from command mode
# https://unix.stackexchange.com/questions/290392/backspace-in-zsh-stuck
bindkey -v '^?' backward-delete-char

# Updates editor information when the keymap changes.
function zle-keymap-select() {
  zle reset-prompt
  zle -R
}
zle -N zle-keymap-select

# Ensure that the prompt is redrawn when the terminal size changes.
TRAPWINCH() {
  zle &&  zle -R
}

bindkey -v
autoload -Uz edit-command-line
bindkey -a '^[v' edit-command-line # equivalent to 'bindkey -M vicmd'
bindkey '^[v' edit-command-line

bindkey '^p' up-history
bindkey '^n' down-history

bindkey '^h' backward-delete-char
bindkey '^d' delete-char
bindkey '^b' backward-char
bindkey '^f' forward-char
bindkey '^o' forward-word
bindkey '^k' kill-line
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

# TODO: remove this vi zle improvements after verifying zsh-vi-mode can cover them.
# # zle functions
# # select quoted
# autoload -U select-quoted
# zle -N select-quoted
# for m in visual viopp; do
# 	for c in {a,i}{\',\",\`}; do
# 	  bindkey -M $m $c select-quoted
# 	done
# done

# # select bracketed
# autoload -U select-bracketed
# zle -N select-bracketed
# for m in visual viopp; do
# 	for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
# 	  bindkey -M $m $c select-bracketed
# 	done
# done

# # surround
# autoload -Uz surround
# zle -N delete-surround surround
# zle -N add-surround surround
# zle -N change-surround surround
# bindkey -a cs change-surround
# bindkey -a ds delete-surround
# bindkey -a ys add-surround
# bindkey -a S add-surround

# zce
bindkey -M vicmd 't' zce

# ranger
# Automatically change the directory in zsh after closing ranger
ranger-cd() {
  tempfile="$(mktemp -t tmp.XXXXXX)"
  ranger --choosedir="$tempfile" "${@:-$(pwd)}"
  test -f "$tempfile" &&
    if [ "$(cat -- "$tempfile")" != "$(echo -n `pwd`)" ]; then
      cd -- "$(cat "$tempfile")"
    fi
  rm -f -- "$tempfile"
}

bindkey -s '^u' 'ranger .^m'
bindkey -s '^[u' 'ranger-cd^m'

# --------------------- Version Management ---------------------
# Lazy Load to speed up zsh start
# Source:
#   https://github.com/xcv58/prezto/blob/master/modules/lazy-load/init.zsh

function lazy_load() {
  local load_func=${1}
  local lazy_func="lazy_${load_func}"

  shift
  for i in ${@}; do
    alias ${i}="${lazy_func} ${i}"
  done

  eval "
          function ${lazy_func}() {
              unset -f ${lazy_func}
              lazy_load_clean $@
              eval ${load_func}
              unset -f ${load_func}
              eval \$@
          }
          "
}

function lazy_load_clean() {
  for i in ${@}; do
    unalias ${i}
  done
}

# pyenv
if which pyenv > /dev/null; then eval "$(pyenv init - --no-rehash)"; fi

# pyenv-virtualenv
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

# nodenv(lazy load)
function load_nodenv() {
  which nodenv > /dev/null && eval "$(nodenv init -)"
}

lazy_load load_nodenv nodenv npm node hexo

# jenv(lazy load)
function load_jenv() {
  if which jenv > /dev/null; then eval "$(jenv init -)"; fi
}

lazy_load load_jenv jenv java javac

# rbenv
function load_rbenv() {
  if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
}

lazy_load load_rbenv rbenv ruby gem pry t

# direnv
if which direnv > /dev/null; then eval "$(direnv hook zsh)"; fi
# _____________________ Version Management _____________________

# --------------------- exa ---------------------
if which exa > /dev/null; then
  _ls_cmd="exa --color always --group-directories-first --sort extension"
  alias ls="$_ls_cmd"
  alias la="$_ls_cmd -al --git --group --header"
  alias ll="$_ls_cmd -l --git --group --header"
  alias l="$_ls_cmd -l --git"
  alias tree="$_ls_cmd --tree --level 2 --git"
  _tree_cmd="$_ls_cmd --tree --level 2"
else
  _ls_cmd="ls --color=tty --group-directories-first"
  alias ls="$_ls_cmd"
  alias ll="$_ls_cmd -lh"
  alias l="$_ls_cmd -lh"
  alias la="$_ls_cmd -lAh"
  _tree_cmd="tree -C"
fi
# _____________________ exa _____________________

# Navi
bindkey '^y' _navi_widget

# --------------------- fzf ---------------------
export FZF_COMPLETION_TRIGGER=':'

_fzf_compgen_dir() {
  fd -H --no-ignore-vcs -t d $1
}

# fzf z binding
__fzf_z() {
  z -i | sed 's/^[0-9,.]* *//' \
    | fzf --tac --reverse --preview "$_tree_cmd {} | head -200" --preview-window right:30%
}

__fzf_z_arg() {
  __fzf_z | while read item; do printf ' %q/' "$item"; done
  echo
}

__fzf_z_arg_widget() {
  LBUFFER="${LBUFFER}$(__fzf_z_arg)"
  local ret=$?
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}

zle -N __fzf_z_arg_widget

# fzf z arg
bindkey '^[j' __fzf_z_arg_widget

__fzf_z_cd_widget() {
  local dir=$(__fzf_z)
  cd "$dir"
  local ret=$?
  zle reset-prompt
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}

zle -N __fzf_z_cd_widget

# fzf z cd
bindkey '^j' __fzf_z_cd_widget

# fzf dirs under current dir
__fzf_dir() {
  set -o nonomatch
  _fzf_compgen_dir . \
    | fzf --tac --reverse --preview "$_tree_cmd {} | head -200" \
    | while read item; do printf ' %q/' "$item"; done
  echo
}

__fzf_dir_widget() {
  LBUFFER="${LBUFFER}$(__fzf_dir)"
  local ret=$?
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}

zle -N __fzf_dir_widget

bindkey '^x' fzf-cd-widget
bindkey '^[x' __fzf_dir_widget
