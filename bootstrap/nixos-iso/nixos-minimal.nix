{ pkgs, modulesPath, lib, ... }:

with lib;

{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  # use the latest Linux kernel
  boot.kernelPackages = pkgs.zfs.latestCompatibleLinuxPackages;

  boot.supportedFilesystems = [ "ext4" "fat32" "zfs" ];

  environment.systemPackages = with pkgs; [ ntfs3g rsync ];

  networking.networkmanager.enable = true;
  networking.wireless.enable = mkImageMediaOverride false;
}
