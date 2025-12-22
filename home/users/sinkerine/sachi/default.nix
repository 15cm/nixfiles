args@{ pkgs, ... }:

{
  home.stateVersion = "23.05";

  imports = [ ../common ../common/trusted.nix ];
  my.programs.baidupcs-go.enable = true;
}
