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
    devNodesOverride = mkOption {
      type = with types; nullOr path;
      default = null;
      description = ''
        Name of directory from which to import ZFS devices.

        This should be a path under /dev containing stable names for all devices needed, as
        import may fail if device nodes are renamed concurrently with a device failing.
      '';
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
    (mkIf cfg.enableNonRootEncryption
      (let encryptedZfsPath = assertNotNull cfg.encryptedZfsPath;
      in {
        systemd.targets.zfs-load-key-and-mount = {
          description = "Mount all zfs datasets, including encrypted ones";
        };
        systemd.services = {
          zfs-load-key = {
            description = "zfs load key for all pools";
            requiredBy = [ "zfs-load-key-and-mount.target" ];
            partOf = [ "zfs-load-key-and-mount.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = ''
                ${pkgs.runtimeShell} -c '${pkgs.zfs}/bin/zfs get keystatus -o value ${encryptedZfsPath} | tail -n 1 | grep -q ^available || until (${config.systemd.package}/bin/systemd-ask-password "Please enter your password for zfs load-key: " --no-tty | ${pkgs.zfs}/bin/zfs load-key ${encryptedZfsPath}); do echo "Try again!"; done'
              '';
              RemainAfterExit = true;
            };
          };
          my-zfs-mount = {
            description = "zfs mount service after zfs-load-key.service";
            after = [ "zfs-load-key.service" ];
            wantedBy = [ "zfs-load-key.service" ];
            requiredBy = [ "zfs-load-key-and-mount.target" ];
            partOf = [ "zfs-load-key-and-mount.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = ''
                ${pkgs.zfs}/bin/zfs mount -a
              '';
              RemainAfterExit = true;
            };
          };
        };
      }))
    (mkIf (cfg.devNodesOverride != null) {
      boot.zfs.devNodes = cfg.devNodesOverride;
    })
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
