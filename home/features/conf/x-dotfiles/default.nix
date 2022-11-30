# Dotfiles related to X that doesn't have a module support or doesn't want completed program modules.

{ mylib, hostname, ... }:

let
  inherit (mylib) templateFile;
  templateData = { inherit hostname; };
in {
  home.file.".imwheelrc".source = ./imwheelrc;
  home.file.".xprofile".source =
    templateFile "xprofile" templateData ./xprofile.sh.jinja;
}
