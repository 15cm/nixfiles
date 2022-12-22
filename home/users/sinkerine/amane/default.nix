args@{ pkgs, ... }:

{
  home.stateVersion = "22.05";

  imports = [ ../common ];
}
