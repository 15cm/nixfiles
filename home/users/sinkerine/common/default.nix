{
  config,
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

  my.services.orca = {
    enable = true;
    mode = lib.mkDefault (if config.my.essentials.gui.enable then "gui" else "headless");
    pairingAddress = "${hostname}.m.mado.moe";
  };
}
