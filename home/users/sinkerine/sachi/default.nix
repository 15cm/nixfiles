{ config, pkgs, ... }:

{
  home.stateVersion = "23.05";

  imports = [ ../common ];

  my.profiles.trusted.enable = true;

  programs.zsh.shellAliases = {
    snh = "switch-nix-home.sh";
    sno = "switch-nix-os.sh";
  };

  my.programs.baidupcs-go.enable = true;

  home.packages = with pkgs; [ nodejs ];
}
