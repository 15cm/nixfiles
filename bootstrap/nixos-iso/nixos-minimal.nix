{ pkgs, modulesPath, lib, ... }:

with lib;

{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  # use the latest Linux kernel
  boot.kernelPackages = pkgs.zfs.latestCompatibleLinuxPackages;

  boot.supportedFilesystems = mkForce [ "ext4" "fat32" "zfs" ];

  environment.systemPackages = with pkgs; [ ntfs3g ];

  networking.networkmanager.enable = true;
  networking.wireless.enable = mkForce false;
}
