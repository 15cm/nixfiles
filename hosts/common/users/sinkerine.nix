{ config, pkgs, ... }:

{
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
  };
}
