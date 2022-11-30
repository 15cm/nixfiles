{ pkgs, mylib, state, ... }:

let
  inherit (mylib) writeShellScriptFile templateFile;
  templateData = { inherit (state) theme; };
in {
  home.packages = [ pkgs.ranger pkgs.ranger_devicons ];

  xdg.configFile = {
    "ranger/rc.conf".source =
      templateFile "ranger-rc.conf" templateData ./rc.conf.jinja;
    "ranger/rifle.conf".source = ./rifle.conf;
    "ranger/commands.py".source = ./commands.py;
    "ranger/scope.sh".source =
      writeShellScriptFile "ranger-scope.sh" ./scope.sh;
    # Do not symlink the colorschemes/ dir because __init__.py will be written by Ranger to there.
    "ranger/colorschemes/custom-dark.py".source = ./colorschemes/custom-dark.py;
    "ranger/colorschemes/custom-light.py".source =
      ./colorschemes/custom-light.py;
    # Plugins
    "ranger/plugins/ranger_devicons".source =
      "${pkgs.ranger_devicons}/share/ranger_devicons";
  };
}
