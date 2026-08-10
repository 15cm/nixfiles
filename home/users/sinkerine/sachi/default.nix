{ config, pkgs, ... }:

{
  home.stateVersion = "26.05";

  imports = [ ../common ];

  my.profiles.trusted.enable = true;

  programs.zsh.shellAliases = {
    snh = "switch-nix-home.sh";
    sno = "switch-nix-os.sh";
  };

  my.programs.baidupcs-go.enable = true;

  my.services.orca = {
    enable = true;
    pairingAddress = "sachi.m.mado.moe";
  };

  home.packages = with pkgs; [ nodejs ];
}
