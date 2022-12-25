{ config, pkgs, lib, ... }:

with lib;

let cfg = config.my.services.docker;
in {
  options.my.services.docker = {
    enable = mkEnableOption "docker";
    waitForManualZfsLoadKey = mkEnableOption
      "Do not start docker on boot but along with the zfs-load-key-and-mount target";
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = !cfg.waitForManualZfsLoadKey;
      storageDriver = "overlay2";
      daemon.settings = {
        userns-remap = "sinkerine:sinkerine";
        default-address-pools = [{
          base = "172.16.0.0/16";
          size = 24;
        }];
        log-driver = mkForce "local";
      };
      autoPrune.enable = true;
    };

    users.groups.dockremap = { gid = config.my.ids.uids.dockremap; };
    users.users.dockremap = {
      isSystemUser = true;
      uid = config.my.ids.uids.dockremap;
      group = "dockremap";
    };

    systemd.sockets.docker = mkIf cfg.waitForManualZfsLoadKey {
      wantedBy = mkForce [ "zfs-load-key-and-mount.target" ];
      partOf = mkForce [ "zfs-load-key-and-mount.target" ];
      after = mkForce [ "socket.target" "zfs-load-key-and-mount.target" ];
    };
    systemd.services.createDockerNetowrk = {
      enable = true;
      description = "Create Docker network";
      wantedBy = [ "docker.service" ];
      after = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "create-docker-network.service" ''
          if ! ${pkgs.docker}/bin/docker network ls | grep -q g_proxy; then ${pkgs.docker}/bin/docker network create g_proxy; fi
        '';
      };
    };
  };
}
