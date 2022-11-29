{ specialArgs, pkgs, lib, ... }:

with lib;
let
  inherit (specialArgs.mylib) templateFile;
  templateData = rec {
    inherit (specialArgs) hostname theme;
    colorScheme = (if theme == "light" then "solarized-light" else "nord-dark");
  };
in {
  home.packages = [ pkgs.i3status-rust ];
  #TODO: go through and fix paths of the scripts called by i3 config.
  xdg.configFile."i3/config.jinja".source =
    templateFile "i3-config" templateData ./config.jinja;
  xdg.configFile."i3/status.toml".source =
    templateFile "i3status-rust" templateData ./status.toml.jinja;
  xdg.configFile."scripts/i3/init.sh".source =
    pipe ./init.sh [ builtins.readFile (pkgs.writeShellScript "i3-init.sh") ];
}
