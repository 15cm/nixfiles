{ config, lib, pkgs, mylib, ... }:

with lib;
let
  cfg = config.my.essentials.zfs;
  inherit (mylib) assertNotNull;
in {
  options.my.essentials.zfs = {
    enable = mkEnableOption "zfs";
    enableNonRootEncryption = mkEnableOption "non root encryption";
    enableZed = mkEnableOption "zed";
    nonRootPools = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "non root pools to be imported on boot";
    };
    encryptedZfsPath = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      boot.supportedFilesystems = [ "zfs" ];
      boot.kernelPackages =
        config.boot.zfs.package.latestCompatibleLinuxPackages;
      boot.zfs.forceImportAll = true;
      boot.zfs.extraPools = cfg.nonRootPools;
      services.zfs.autoScrub.enable = true;
    }
    (mkIf cfg.enableZed {
      services.zfs.zed = {
        # this option does not work; will return error
        enableMail = false;
        settings = {
          ZED_DEBUG_LOG = "/tmp/zed.debug.log";
          ZED_EMAIL_ADDR = [ "root" ];
          ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
          ZED_EMAIL_OPTS = "@ADDRESS@";

          ZED_NOTIFY_INTERVAL_SECS = 3600;

          ZED_USE_ENCLOSURE_LEDS = true;
          ZED_SCRUB_AFTER_RESILVER = true;
        };
      };
    })
  ]);
}
