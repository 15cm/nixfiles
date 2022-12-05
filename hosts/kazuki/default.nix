{ config, pkgs, lib, mylib, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports =
    [ ../common/baseline.nix ../common/zfs.nix ../common/users/sinkerine.nix ]
    ++ [
      ./generated/hardware-configuration.nix
      ./generated/extra-configuration.nix
    ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = { hashedPassword.neededForUsers = true; };
    age = { keyFile = "/keys/age/kazuki.txt"; };
  };

  boot.kernelParams = [ "nvidia-drm.modeset=1" ];
}
