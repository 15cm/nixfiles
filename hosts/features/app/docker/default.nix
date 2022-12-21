{ pkgs, lib, ... }:

with lib;

{
  imports = [ ../../../common/users/dockremap.nix ];
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
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
  systemd.sockets.docker = {
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
}
