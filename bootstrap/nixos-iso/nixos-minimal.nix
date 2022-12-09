{ pkgs, modulesPath, lib, ... }:

with lib;

{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  # use the latest Linux kernel
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  boot.supportedFilesystems = mkForce [ "ext4" "fat32" "zfs" ];

  networking.networkmanager.enable = true;
  networking.wireless.enable = mkForce false;
}
