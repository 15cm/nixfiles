# ==========================================
# Custom Zsh Configuration (Darwin / macOS)
# Derived from host 'amane' configuration
# ==========================================

# --------------------- Globals & Env ---------------------
export TZ="America/Los_Angeles"
export PATH="$PATH:$HOME/local/bin:/usr/local/bin:/usr/bin"

if which nvim > /dev/null 2>&1; then
  export EDITOR="nvim"
else
  export EDITOR="vim"
fi

export TLDR_COLOR_BLANK="blue"
export TLDR_COLOR_DESCRIPTION="green"
export TLDR_COLOR_PARAMETER="blue"
export ZSH_AUTOSUGGEST_USE_ASYNC=true
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#a8a8a8,underline"
export GPG_TTY="$(tty)"
export KEYTIMEOUT=1
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# Only check zcompdump per day
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit;
else
  compinit -C;
fi;

# This allows us to override the zvm keybindings later.
# https://github.com/jeffreytse/zsh-vi-mode#initialization-mode
export ZVM_INIT_MODE=sourcing

zstyle :omz:plugins:ssh-agent lazy yes
zstyle :omz:plugins:ssh-agent quiet yes

# --------------------- Symlinks & Dotfiles Management ---------------------
# Ensure ~/.zimrc is symlinked to our dotfiles .zimrc
if [[ ! -h ~/.zimrc || "$(readlink ~/.zimrc)" != *"/darwin-dotfiles/.zimrc" ]]; then
  echo "Creating ~/.zimrc symlink..."
  rm -f ~/.zimrc
  ln -s "${0:A:h}/.zimrc" ~/.zimrc
fi

# Ensure ~/.config/tmux/tmux.conf is symlinked to our dotfiles tmux.conf
if [[ ! -h ~/.config/tmux/tmux.conf || "$(readlink ~/.config/tmux/tmux.conf)" != *"/darwin-dotfiles/.config/tmux/tmux.conf" ]]; then
  echo "Creating ~/.config/tmux/tmux.conf symlink..."
  mkdir -p ~/.config/tmux
  rm -f ~/.config/tmux/tmux.conf
  ln -s "${0:A:h}/.config/tmux/tmux.conf" ~/.config/tmux/tmux.conf
fi

# Ensure ~/Library/Preferences/com.amethyst.Amethyst.plist is symlinked
if [[ ! -h ~/Library/Preferences/com.amethyst.Amethyst.plist || "$(readlink ~/Library/Preferences/com.amethyst.Amethyst.plist)" != *"/darwin-dotfiles/Library/Preferences/com.amethyst.Amethyst.plist" ]]; then
  echo "Creating ~/Library/Preferences/com.amethyst.Amethyst.plist symlink..."
  mkdir -p ~/Library/Preferences
  if [[ -f ~/Library/Preferences/com.amethyst.Amethyst.plist && ! -h ~/Library/Preferences/com.amethyst.Amethyst.plist ]]; then
    mv ~/Library/Preferences/com.amethyst.Amethyst.plist ~/Library/Preferences/com.amethyst.Amethyst.plist.bak
  fi
  rm -f ~/Library/Preferences/com.amethyst.Amethyst.plist
  ln -s "${0:A:h}/Library/Preferences/com.amethyst.Amethyst.plist" ~/Library/Preferences/com.amethyst.Amethyst.plist
fi

# Ensure ~/.gitconfig is symlinked to our dotfiles .gitconfig
if [[ ! -h ~/.gitconfig || "$(readlink ~/.gitconfig)" != *"/darwin-dotfiles/.gitconfig" ]]; then
  echo "Creating ~/.gitconfig symlink..."
  if [[ -f ~/.gitconfig && ! -h ~/.gitconfig ]]; then
    mv ~/.gitconfig ~/.gitconfig.bak
  fi
  rm -f ~/.gitconfig
  ln -s "${0:A:h}/.gitconfig" ~/.gitconfig
fi

# Ensure ~/.gitignore_global is symlinked to our dotfiles .gitignore_global
if [[ ! -h ~/.gitignore_global || "$(readlink ~/.gitignore_global)" != *"/darwin-dotfiles/.gitignore_global" ]]; then
  echo "Creating ~/.gitignore_global symlink..."
  if [[ -f ~/.gitignore_global && ! -h ~/.gitignore_global ]]; then
    mv ~/.gitignore_global ~/.gitignore_global.bak
  fi
  rm -f ~/.gitignore_global
  ln -s "${0:A:h}/.gitignore_global" ~/.gitignore_global
fi


export ZIM_HOME=${ZIM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/zim}

# Download zimfw plugin manager if missing
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  echo "Installing zimfw..."
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Source zimfw.zsh
source ${ZIM_HOME}/zimfw.zsh

# Read active modules from ~/.zimrc to check if installation is needed
local install_needed=0
if [[ -f ~/.zimrc ]]; then
  while read -r line; do
    [[ "${line}" != zmodule* ]] && continue
    local mod="${line#zmodule }"
    local mod_repo="${mod%% *}"
    local mod_name="${mod_repo##*/}"
    # Special case for ohmyzsh submodules
    if [[ "${mod}" == *"--root"* ]]; then
      local subpath="${mod##*--root }"
      subpath="${subpath%% *}"
      if [[ ! -d ${ZIM_HOME}/modules/${mod_name}/${subpath} ]]; then
        install_needed=1
        break
      fi
    elif [[ ! -d ${ZIM_HOME}/modules/${mod_name} ]]; then
      install_needed=1
      break
    fi
  done < ~/.zimrc
fi

if (( install_needed )) || [[ ! -e ${ZIM_HOME}/init.zsh ]]; then
  echo "Installing and compiling missing zimfw modules..."
  zsh ${ZIM_HOME}/zimfw.zsh install
fi

# Source the generated init.zsh
source ${ZIM_HOME}/init.zsh

# --------------------- Options ---------------------
setopt autocd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

# --------------------- Shell Aliases ---------------------
alias md="mkdir -p"
alias rz="exec $SHELL"
alias cdg="cd-gitroot"
alias prl="parallel"
alias grep="grep --color=auto"
alias rp="realpath"
alias ew="$EDITOR"
alias op="open"
alias cpy="pbcopy"
alias pst="pbpaste"
alias th="trash"

# Directory navigation
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

# Sudo expand alias support
alias sudo="sudo "
alias _="sudo"

# Tmux control aliases
alias ta="tmux attach -t"
alias tad="tmux attach -d -t"
alias ts="tmux new -A -s"
alias tl="tmux list-sessions"
alias tksv="tmux kill-server"
alias tkss="tmux kill-session -t"

# --------------------- Standard & Robust ls ---------------------
if ls --color=auto --group-directories-first >/dev/null 2>&1; then
  alias ls="ls --color=auto --group-directories-first"
elif ls --color=auto >/dev/null 2>&1; then
  alias ls="ls --color=auto"
else
  alias ls="ls -G"
fi
alias ll="ls -lh"
alias l="ls -lh"
alias la="ls -lah"

# Disable Ctrl-s which freezes the terminal
stty -ixon

# Enable editing current command in editors.
autoload edit-command-line
zle -N edit-command-line

# <tab> selection color
zstyle ':completion:*' menu select

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

# zle keybindings
autoload -Uz edit-command-line
bindkey -a '^[v' edit-command-line
bindkey '^[v' edit-command-line

# Mainly to accept a word in zsh auto suggestion.
bindkey '^o' forward-word

# Home & End keys
bindkey -M vicmd "^[[1~" beginning-of-line
bindkey -M viins "^[[1~" beginning-of-line
bindkey -M vicmd "^[[4~" end-of-line
bindkey -M viins "^[[4~" end-of-line

# zce
bindkey -M vicmd 't' zce

bindkey -s '^u' 'yazi_zsh^m'

# direnv
if which direnv > /dev/null; then eval "$(direnv hook zsh)"; fi

# Navi
bindkey '^y' _navi_widget

# --------------------- fzf ---------------------
export FZF_COMPLETION_TRIGGER=':'
if which fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

_fzf_compgen_dir() {
  fd -H --no-ignore-vcs -t d . "$1"
}

# fzf z cd
bindkey -s '^j' '__zoxide_zi^m'

# fzf dirs under current dir
__fzf_dir() {
  set -o nonomatch
  _fzf_compgen_dir . \
    | fzf --tac --reverse --preview "tree -C {} | head -200" \
    | while read item; do printf ' %q' "$item"; done
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

bindkey '^f' fzf-cd-widget
bindkey '^x' __fzf_dir_widget

# Remove alt bindings of fzf because it conflicts with zsh vi mode. Esc and Alt sends the same key code '^['.
bindkey -r viins '^[c'
bindkey -r vicmd '^[c'

# --------------------- Premium Minimalist Prompt ---------------------
# Replaces powerline status line with a modern, lightweight prompt
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%F{magenta}git:(%F{red}%b%F{magenta})%f '
zstyle ':vcs_info:git:*' actionformats '%F{magenta}git:(%F{red}%b%F{magenta}|%F{yellow}%a%F{magenta})%f '

precmd() {
  vcs_info
}

setopt prompt_subst
PROMPT='%F{green}%n%f at %F{blue}%m%f in %F{cyan}%~%f ${vcs_info_msg_0_}
%F{yellow}➜%f '
