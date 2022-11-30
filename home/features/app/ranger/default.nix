{ pkgs, mylib, state, ... }:

let
  inherit (mylib) writeShellScriptFile templateFile;
  templateData = { inherit (state) theme; };
in {
  home.packages = [ pkgs.ranger ];

  # TODO: create a package for https://github.com/alexanderjeurissen/ranger_devicons and add it to ~/.config/ranger/plugins/ranger_devicons
  xdg.configFile = {
    "ranger/rc.conf".source =
      templateFile "ranger-rc.conf" templateData ./rc.conf.jinja;
    "ranger/rifle.conf".source = ./rifle.conf;
    "ranger/commands.py".source = ./commands.py;
    "ranger/scope.sh".source =
      writeShellScriptFile "ranger-scope.sh" ./scope.sh;
    "ranger/colorschemes".source = ./colorschemes;
  };
}
