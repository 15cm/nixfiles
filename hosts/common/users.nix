{ config, pkgs, lib, ... }:

with lib;

{
  users.groups.sinkerine = { gid = config.my.ids.uids.sinkerine; };
  users.users.sinkerine = {
    isNormalUser = true;
    shell = pkgs.zsh;
    group = "sinkerine";
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "bluetooth"
      "networkmanager"
      "docker"
      "libvirtd"
      "dockremap"
      "wireshark"
      "camera"
    ];
    uid = config.my.ids.uids.sinkerine;
    home = "/home/sinkerine";
    hashedPasswordFile = config.sops.secrets.hashedPassword.path;
    subUidRanges = [{
      startUid = config.my.ids.uids.dockremap;
      count = 65536;
    }];
    subGidRanges = [{
      startGid = config.my.ids.uids.dockremap;
      count = 65536;
    }];

    openssh.authorizedKeys.keys = config.my.trusts.ssh.pubKeys;
  };

  users.users.root = {
    openssh.authorizedKeys.keys = config.my.trusts.ssh.pubKeys;
  };

  users.groups.smtp-secret = { gid = config.my.ids.uids.smtp-secret; };

  sops.secrets.cameraHashedPassword = { sopsFile = ./secrets.yaml; };
  users.users.camera = {
    isSystemUser = true;
    uid = config.my.ids.uids.camera;
    group = "camera";
    hashedPasswordFile = config.sops.secrets.cameraHashedPassword.path;
  };
  users.groups.camera = { gid = config.my.ids.uids.camera; };
}
