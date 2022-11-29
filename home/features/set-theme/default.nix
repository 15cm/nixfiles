args@{ pkgs, config, specialArgs, ... }:

let
  commonConfig = (import ../../common/config.nix args);
  templateData = {
    statePath = "${commonConfig.nix.projectRoot}/home/state/default.nix";
    flakeUri = "${commonConfig.nix.flakeUri}";
    powerlineTmuxConfPath =
      "${config.programs.powerline.package}/share/tmux/powerline.conf";
  };
  inherit (specialArgs.mylib) templateShellScriptFile;
in {
  home.file."local/bin/set-theme.sh".source =
    templateShellScriptFile "set-theme.sh" templateData
    ./set-theme-command-base.sh.jinja;
  programs.zsh.shellAliases = {
    stl = "set-theme.sh light";
    std = "set-theme.sh dark";
  };
}
