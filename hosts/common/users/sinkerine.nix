{ config, pkgs, ... }:

let pubCredentials = import (../pub-credentials);
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

    openssh.authorizedKeys.keys = pubCredentials.ssh.keys;
  };
}
