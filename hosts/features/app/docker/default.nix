{ pkgs, lib, ... }:

with lib;

{
  imports = [ ../../../common/users/dockremap.nix ];
  virtualisation.docker = {
    enable = true;
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
  systemd.services.createDockerNetowrk = {
    enable = true;
    description = "Create Docker network";
    wantedBy = [ "default.target" ];
    after = [ "docker.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "create-docker-network.service" ''
        if ! ${pkgs.docker}/bin/docker network ls | grep -q g_proxy; then ${pkgs.docker}/bin/docker network create g_proxy; fi
      '';
    };
  };
}
