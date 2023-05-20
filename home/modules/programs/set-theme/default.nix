{ pkgs, config, lib, nixinfo, mylib, isLinuxGui, state, ... }:

with lib;
let
  cfg = config.my.programs.set-theme;
  inherit (mylib) mkDefaultTrueEnableOption;
in {
  options.my.programs.set-theme = {
    enable = mkDefaultTrueEnableOption "set-theme";
  };

  config = mkIf cfg.enable {
    home.file."local/bin/set-theme.sh".source =
      pkgs.writeShellScript "set-theme.sh" ''
        sed -i "s/\(theme.*\)\"[^\"]*\"/\1\"$1\"/" ${nixinfo.projectRoot}/home/state/default.nix
        switch-nix-home.sh
      '';

    home.file."local/bin/reload-theme.sh".source =
      pkgs.writeShellScript "reload-theme.sh" ''
        ${config.programs.powerline.package}/bin/powerline-daemon --replace
        ${pkgs.tmux}/bin/tmux source ${config.programs.powerline.package}/share/tmux/powerline.conf
        ${config.my.programs.emacs.package}/bin/emacsclient -eun '(load "~/.config/emacs/scripts/load-theme.el")'
        exit 0
      '';

    programs.zsh.shellAliases = {
      stl = "set-theme.sh light";
      std = "set-theme.sh dark";
    };

    home.activation.reloadTheme = hm.dag.entryAfter [ "writeBoundary" ] ''
      ${config.home.homeDirectory}/local/bin/reload-theme.sh ${
        if isLinuxGui then "gui" else "cli"
      }
    '';
  };
}
