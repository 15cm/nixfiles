{ config, pkgs, ... }:

{
  home.stateVersion = "23.05";

  imports = [ ../common ];

  my.profiles.trusted.enable = true;

  my.programs.baidupcs-go.enable = true;

  home.packages = with pkgs; [ nodejs ];
}
