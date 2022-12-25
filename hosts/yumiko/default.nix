{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports = [
    ./generated/hardware-configuration.nix
    ./generated/extra-configuration.nix
    ../common/baseline.nix
    ../common/grub-legacy.nix
    ../common/zfs
    ../common/zfs/non-root.nix
    ../common/users.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = { hashedPassword.neededForUsers = true; };
    age = {
      keyFile = "/keys/age/${hostname}.txt";
      sshKeyPaths = [ ];
    };
    # https://github.com/Mic92/sops-nix/issues/167
    gnupg.sshKeyPaths = [ ];
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    permitRootLogin = "prohibit-password";
  };

  networking = {
    hostName = hostname;
    domain = "15cm.net";
    useDHCP = true;
  };

  my.services.zrepl = {
    enable = true;
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/yumiko.machine.15cm.net.crt;
    sopsKeyFile = ./zrepl/yumiko.machine.15cm.net.key;
    openFirewall = true;
  };
}
