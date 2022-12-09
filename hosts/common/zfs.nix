{ config, pkgs, ... }:

{
  # hostid is required by zfs and must be provided in the generated configurations like:
  # networking.hostId = "$(head -c 8 /etc/machine-id)";

  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # Bootloader
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  services.zfs = { autoScrub.enable = true; };
}
