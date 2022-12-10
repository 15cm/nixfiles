args@{ pkgs, config, nixinfo, mylib, state, ... }:

let
  templateData = {
    statePath = "${nixinfo.projectRoot}/home/state/default.nix";
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
