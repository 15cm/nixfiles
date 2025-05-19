{ pkgs, modulesPath, lib, ... }:

with lib;

{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  # use the latest Linux kernel
  boot.kernelPackages = mkForce pkgs.linuxPackages_6_6;

  boot.supportedFilesystems = [ "ext4" "fat32" "zfs" ];

  environment.systemPackages = with pkgs; [ ntfs3g rsync git ];

  networking.networkmanager.enable = true;
  networking.wireless.enable = mkImageMediaOverride false;
}
