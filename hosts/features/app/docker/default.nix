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
  system.activationScripts.createDockerNetowrk = ''
    ${pkgs.docker}/bin/docker network ls | grep -q g_proxy || ${pkgs.docker}/bin/docker network create g_proxy
  '';
}
