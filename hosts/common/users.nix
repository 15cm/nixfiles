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
    ];
    uid = config.my.ids.uids.sinkerine;
    home = "/home/sinkerine";
    passwordFile = config.sops.secrets.hashedPassword.path;
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
}
