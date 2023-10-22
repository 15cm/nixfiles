{ config, lib, pkgs, nixinfo, ... }:

with lib;
let
  cfg = config.my.programs.zsh;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in {
  options.my.programs.zsh = {
    enable = mkEnableOption "Zsh";
    package = mkOption {
      type = types.package;
      default = pkgs.zsh;
      defaultText = literalExpression "pkgs.zsh";
      description = "The zsh package to use.";
    };
    isXorg = mkOption {
      type = types.bool;
      default = false;
      description = "Is XOrg";
    };
  };

  config = mkIf cfg.enable ({
    programs.zsh = {
      enable = true;
      enableCompletion = false;
      zplug = {
        enable = true;
        plugins = [
          {
            name = "zsh-users/zsh-autosuggestions";
            tags = [ "defer:2" ];
          }
          {
            name = "zsh-users/zsh-syntax-highlighting";
            tags = [ "defer:3" "on:zsh-users/zsh-autosuggestions" ];
          }
          { name = "mollifier/cd-gitroot"; }
          { name = "15cm/yadm-zsh"; }
          { name = "15cm/zce.zsh"; }
          {
            name = "plugins/fzf";
            tags = [ "defer:2" "from:oh-my-zsh" ];
          }
          {
            name = "plugins/git";
            tags = [ "from:oh-my-zsh" ];
          }
          {
            name = "jeffreytse/zsh-vi-mode";
            tags = [ "defer:0" ];
          }
        ] ++ optionals (nixinfo.configName != "work@desktop") [{
          name = "plugins/ssh-agent";
          tags = [ "from:oh-my-zsh" ];
        }];
      };

      history = {
        path = "${config.home.homeDirectory}/.zsh_history";
        size = 1000000000;
        save = 1000000000;
        ignoreDups = true;
      };
      sessionVariables = {
        LC_ALL = "en_US.utf-8";
        LANG = "en_US.utf-8";
        LANGUAGE = "en_US.UTF-8";
        NIX_PATH =
          "$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels\${NIX_PATH:+:$NIX_PATH}";
        CARGO_HOME = "${config.xdg.cacheHome}/cargo";
      } // optionalAttrs isDarwin { HOMEBREW_NO_AUTO_UPDATE = "1"; };
      # Env vars that are specific to interactive shell.
      initExtraFirst = mkBefore ''
        # zmodload zsh/zprof
        export TZ="America/Los_Angeles"
        export PATH="$PATH:$HOME/local/bin:/usr/local/bin:/usr/bin";
        export EDITOR="${config.home.homeDirectory}/local/bin/exec-editor.sh";
        export TERM="alacritty";
        export TLDR_COLOR_BLANK="blue";
        export TLDR_COLOR_DESCRIPTION="green";
        export TLDR_COLOR_PARAMETER="blue";
        export ZSH_AUTOSUGGEST_USE_ASYNC=true;
        export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#a8a8a8,underline";
        export GPG_TTY="$(tty)"
        export KEYTIMEOUT=1
        # Only the chars in this list are skipped in word operations.
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
      '';
      initExtra = builtins.readFile ./zshrc;

      shellAliases = {
        md = "mkdir -p";
        rz =
          "unset __HM_SESS_VARS_SOURCED; unset __HM_ZSH_SESS_VARS_SOURCED; exec $SHELL";
        cdg = "cd-gitroot";
        prl = "parallel";
        grep = "grep --color=auto";
        rp = "realpath";

        # Editors
        vi = "vim";
        ew = "$EDITOR";

        # Tmux
        ta = "tmux attach -t";
        tad = "tmux attach -d -t";
        ts = "tmux new -A -s";
        tl = "tmux list-sessions";
        tksv = "tmux kill-server";
        tkss = "tmux kill-session -t";

        # Misc
        op = (if isLinux then "xdg-open" else "open");
        cpy = config.my.services.clipper.copyCommand;
        pst = (if isLinux then
          (if cfg.isXorg then "xclip -o" else "wl-paste")
        else
          "pbpaste");
        th = (if isLinux then "trash-put" else "trash");
        dockerrl = "DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock docker";
      } // optionalAttrs isLinux {
        sc = "sudo systemctl";
        scu = "systemctl --user";
      };
    };
    home.packages = [ pkgs.lua ];
  });
}
