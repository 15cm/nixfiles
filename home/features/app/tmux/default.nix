args@{ config, pkgs, lib, mylib, ... }:

with lib;
let
  commonConfig = (import ../../../common/config.nix args);
  inherit (mylib) templateFile;
  templateData = {
    tmuxFzfScriptsDir =
      "${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts";
    inherit (config.home) sessionVariables;
    inherit (config.my.services.clipper) copyCommand;
  };
in {

  imports = [ ../fzf ];
  programs.tmux = rec {
    enable = true;
    shell = "$SHELL";
    sensibleOnTop = true;
    prefix = "F8";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 20000;
    keyMode = "vi";
    terminal = "tmux";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      continuum
      extrakto
      jump
      tmux-fzf
    ];
  };
  # Place my config between mkBefore and mkDefault
  xdg.configFile."tmux/tmux.conf".text = pipe ./tmux.conf.jinja [
    (templateFile "tmux.conf" templateData)
    builtins.readFile
    (mkOrder 600)
  ];
}
