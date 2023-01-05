{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  services.zfs = { autoScrub.enable = true; };
}
