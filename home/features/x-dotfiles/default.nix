# Dotfiles related to X that doesn't have a module support or doesn't want completed program modules.

{ specialArgs, ... }:

let
  inherit (specialArgs.mylib) templateFile;
  templateData = { inherit (specialArgs) hostname; };
in {
  home.file.".imwheelrc".source = ./imwheelrc;
  home.file.".xprofile".source =
    templateFile "xprofile" templateData ./xprofile.sh.jinja;
}
