# Dotfiles related to X that doesn't have a module support or doesn't want completed program modules.

{ withArgs, ... }:

{
  home.file.".imwheelrc".source = ./imwheelrc;
  home.file.".xprofile".text = (builtins.readFile ./xprofile) + "\n\n"
    + withArgs.xprofile.extraConfig;
}
