{ config, pkgs, lib, ... }:

with lib;

let pubCredentials = import (../pub-credentials);
in {
  users.groups.sinkerine = { gid = 1000; };
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
    uid = 1000;
    home = "/home/sinkerine";
    passwordFile = config.sops.secrets.hashedPassword.path;
    subUidRanges = [{
      startUid = 100000;
      count = 65536;
    }];
    subGidRanges = [{
      startGid = 100000;
      count = 65536;
    }];

    openssh.authorizedKeys.keys = pubCredentials.ssh.keys;
  };
}
