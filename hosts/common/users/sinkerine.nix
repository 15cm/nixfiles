{ config, pkgs, ... }:

let keys = import (../keys.nix);
in {
  users.users.sinkerine = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "bluetooth"
      "networkmanager"
      "docker"
      "libvirtd"
    ];
    uid = 1000;
    home = "/home/sinkerine";
    passwordFile = config.sops.secrets.hashedPassword.path;

    openssh.authorizedKeys.keys = keys.sshKeys;
  };
}
