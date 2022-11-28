args@{ config, lib, pkgs, ... }:

let
  commonConfig = (import ../../common/config.nix args);
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in {
  programs.zsh = {
    enable = true;
    zplug = {
      enable = true;
      plugins = [
        {
          name = "zsh-users/zsh-completions";
          tags = [ "defer:0" ];
        }

        {
          name = "zsh-users/zsh-autosuggestions";
          tags = [ "defer:2" "on:zsh-users/zsh-completions" ];
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
          tags = [ "from:oh-my-zsh" ];
        }
        {
          name = "plugins/git";
          tags = [ "from:oh-my-zsh" ];
        }
        { name = "jeffreytse/zsh-vi-mode"; }
      ];
    };

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 1000000000;
      save = 1000000000;
      ignoreDups = true;
    };
    sessionVariables = {
      PATH = "$PATH:$HOME/.local/bin";
      EDITOR = ./exec-editor.sh;
      LC_ALL = "en_US.utf-8";
      LANG = "en_US.utf-8";
    } // (if isDarwin then { HOMEBREW_NO_AUTO_UPDATE = "1"; } else { });
    initExtraFirst = (builtins.readFile ./extra-first.zshrc);
    initExtra = (builtins.readFile ./extra.zshrc) + ''
    '';

    shellAliases = {
      md = "mkdir -p";
      stl = "set-theme.sh light";
      std = "set-theme.sh dark";
      rz = "exec $SHELL";
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
      ts = "tmux new-session -s";
      tl = "tmux list-sessions";
      tksv = "tmux kill-server";
      tkss = "tmux kill-session -t";

      # Misc
      op = (if isLinux then "xdg-open" else "open");
      cpy = commonConfig.clipper.copyCommand;
      pst = (if isLinux then "xclip -o" else "pbpaste");
      th = (if isLinux then "trash-put" else "trash");
    } // (if isLinux then {
      sc = "sudo systemctl";
      scu = "systemctl --user";
      ssh = "ssh -F ${../ssh/interactive.conf}";
    } else
      { });
  };

  home.packages = [ pkgs.lua ];
}
