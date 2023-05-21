{ pkgs, nixinfo, ... }:

{
  home = rec {
    username = "sinkerine";
    homeDirectory = "/home/${username}";
  };

  imports = [ ../../../common/baseline.nix  ];
}
