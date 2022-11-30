args@{ mylib, hostname, state, pkgs, lib, ... }:

with lib;
let
  emacsConfig = (import ../../app/emacs/config.nix args);
  inherit (mylib) templateFile templateShellScriptFile writeShellScriptFile;
  templateData = rec {
    inherit hostname;
    inherit (state) theme;
    colorScheme = (if theme == "light" then "solarized-light" else "nord-dark");
    monitors = {
      one = "DP-0";
      two = "DP-2";
    };
    emacsSocketPath = emacsConfig.socket.gui.path;
  };
in {
  home.packages = [ pkgs.i3status-rust pkgs.i3-quickterm ];
  #TODO: go through and fix paths of the scripts called by i3 config.
  xdg.configFile."i3/config.jinja".source =
    templateFile "i3-config" templateData ./config.jinja;
  xdg.configFile."i3/status.toml".source =
    templateFile "i3status-rust" templateData ./status.toml.jinja;

  # Scripts
  xdg.configFile."i3/scripts/init.sh".source =
    writeShellScriptFile "i3-scripts-init.sh" ./scripts/init.sh;
  xdg.configFile."i3/scripts/start-emacs-one-instance.sh".source =
    templateShellScriptFile "i3-scripts-start-emacs-one-instance.sh"
    templateData ./scripts/start-emacs-one-instance.sh.jinja;
  xdg.configFile."i3/scripts/i3exit.sh".source =
    writeShellScriptFile "i3-scripts-i3exit.sh" ./scripts/i3exit.sh;
}
