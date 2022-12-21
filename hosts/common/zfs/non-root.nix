{ config, pkgs, lib, encryptedZfsPool, ... }:

with lib; {
  # Usage: sudo systemctl start/stop zfs-load-key-and-mount.target
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
          ${pkgs.runtimeShell} -c 'until (${config.systemd.package}/bin/systemd-ask-password "Please enter your password for zfs load-key: " --no-tty | ${pkgs.zfs}/bin/zfs load-key ${encryptedZfsPool}); do echo "Try again!"; done'
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
