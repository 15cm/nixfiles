{ config, pkgs, lib, ... }:

with lib;

let cfg = config.my.services.docker;
in {
  options.my.services.docker = { enable = mkEnableOption "docker"; };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
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
      isNormalUser = true;
      uid = config.my.ids.uids.dockremap;
      group = "dockremap";
      openssh.authorizedKeys.keys = config.my.trusts.ssh.pubKeys;
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
