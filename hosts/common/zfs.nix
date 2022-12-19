{ config, pkgs, ... }:

{
  # hostid is required by zfs and must be provided in the generated configurations like:
  # networking.hostId = "$(head -c 8 /etc/machine-id)";

  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  services.zfs = { autoScrub.enable = true; };
}
