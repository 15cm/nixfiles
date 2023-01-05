{ config, pkgs, lib, encryptedZfsPath, ... }:

with lib; {
  # Usage: sudo systemctl start/stop zfs-load-key-and-mount.target
  systemd.targets.zfs-load-key-and-mount = {
    description = "Mount all zfs datasets, including encrypted ones";
  };
  systemd.services = {
    zfs-import-pool = {
      description = "zfs import pools";
      wantedBy = [ "zfs.target" ];
      after = [ "zfs.target" ];
      requiredBy = [ "zfs-load-key-and-mount.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.zfs}/bin/zpool import -a -f -N
        '';
        RemainAfterExit = true;
      };
    };
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
}
