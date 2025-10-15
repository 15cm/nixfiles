args@{ pkgs, ... }:

{
  home.stateVersion = "23.05";

  imports = [ ../common ];
  my.programs.baidupcs-go.enable = true;
}
