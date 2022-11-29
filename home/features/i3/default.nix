{ mylib, hostname, state, pkgs, lib, ... }:

with lib;
let
  inherit (mylib) templateFile;
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
  home.packages = [ pkgs.i3status-rust ];
  #TODO: go through and fix paths of the scripts called by i3 config.
  xdg.configFile."i3/config.jinja".source =
    templateFile "i3-config" templateData ./config.jinja;
  xdg.configFile."i3/status.toml".source =
    templateFile "i3status-rust" templateData ./status.toml.jinja;

  # Scripts
  xdg.configFile."i3/scripts/init.sh".source =
    pipe ./init.sh [ builtins.readFile (pkgs.writeShellScript "i3-init.sh") ];
}
