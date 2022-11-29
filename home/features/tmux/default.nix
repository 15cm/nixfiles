args@{ config, pkgs, lib, specialArgs, ... }:

with lib;
let
  commonConfig = (import ../../common/config.nix args);
  inherit (specialArgs.mylib) templateFile;
  templateData = {
    shell = commonConfig.shell.binary;
    tmuxFzfScriptsDir =
      "${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts";
    inherit (config.home) sessionVariables;
    copyCommand = "${commonConfig.clipper.copyCommand}";
  };
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
      tmux-fzf
    ];
    extraConfig = pipe ./tmux.conf.jinja [
      (templateFile "tmux.conf" templateData)
      builtins.readFile
    ];
  };
}
