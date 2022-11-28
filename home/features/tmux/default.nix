args@{ config, pkgs, ... }:

let commonConfig = (import ../../common/config.nix args);
in {

  imports = [ ../fzf ];
  programs.tmux = rec {
    enable = true;
    shell = commonConfig.shell.binary;
    sensibleOnTop = true;
    prefix = "F8";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 20000;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      resurrect
      continuum
      pain-control
      extrakto
      jump
      # fzf
    ];
    extraConfig = ''
      # Start a non-login shell
      set -g default-command "${shell}"

      # Copy mode key bindings
      bind-key -t vi-copy y copy-pipe "${commonConfig.clipper.copyCommand}"

      # Extrakto
      set -g @extrakto_fzf_tool fzf
      set -g @extrakto_key o
      set -g @extrakto_split_size 20
      set -g @extrakto_fzf_options "${config.home.sessionVariables.FZF_DEFAULT_OPTS}"
      set -g @extrakto_opts "path/url word lines"
      set -g @extrakto_clip_tool "${commonConfig.clipper.copyCommand}"

      # Powerline
      source ${pkgs.python3Packages.powerline}/share/tmux/powerline.conf
    '';
  };

  home.packages = [ pkgs.python3Packages.powerline ];
}
