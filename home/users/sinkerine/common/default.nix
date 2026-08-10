{
  pkgs,
  lib,
  nixinfo,
  hostname,
  ...
}:

{
  home = rec {
    username = "sinkerine";
    homeDirectory = "/home/${username}";
  };

  imports = [ ../../../common/baseline.nix ];

  my.services.orca =
    lib.mkIf
      (builtins.elem hostname [
        "sachi"
        "amane"
      ])
      {
        enable = true;
        pairingAddress = "${hostname}.m.mado.moe";
      };
}
