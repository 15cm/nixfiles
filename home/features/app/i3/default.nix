args@{ mylib, hostname, state, pkgs, lib, ... }:

with lib;
let
  inherit (mylib) templateFile templateShellScriptFile writeShellScriptFile;
  templateData = rec {
    inherit hostname;
    inherit (state) theme;
    colorScheme = (if theme == "light" then "solarized-light" else "nord-dark");
    monitors = {
      one = "DP-0";
      two = "DP-2";
    };
  };
in {
  xsession.windowManager.i3 = {
    enable = true;
    config = null;
    extraConfig = pipe ./config.jinja [
      (templateFile "i3-config" templateData)
      builtins.readFile
    ];
  };

  # i3 Scripts
  xdg.configFile."i3/scripts/i3exit.sh".source =
    writeShellScriptFile "i3-scripts-i3exit.sh" ./scripts/i3exit.sh;

  # Other i3 related packages.
  home.packages = [ pkgs.i3status-rust pkgs.i3-quickterm ];
  xdg.configFile."i3/status.toml".source =
    templateFile "i3status-rust" templateData ./status.toml.jinja;
  xdg.configFile."i3/i3-quickterm.json".source = ./i3-quickterm.json;
}
