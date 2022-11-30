args@{ pkgs, config, mylib, state, ... }:

let
  commonConfig = (import ../../../common/config.nix args);
  templateData = {
    statePath = "${commonConfig.nixinfo.projectRoot}/home/state/default.nix";
    flakeUri = "${commonConfig.nixinfo.flakeUri}";
    powerlineTmuxConfPath =
      "${config.programs.powerline.package}/share/tmux/powerline.conf";
  };
  inherit (mylib) templateShellScriptFile;
in {
  home.file."local/bin/set-theme.sh".source =
    templateShellScriptFile "set-theme.sh" templateData
    ./set-theme-command-base.sh.jinja;

  programs.zsh.shellAliases = {
    stl = "set-theme.sh light";
    std = "set-theme.sh dark";
  };
}
