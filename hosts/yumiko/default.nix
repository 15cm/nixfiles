{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports = [
    ./hardware-configuration.nix
    ../common/baseline.nix
    ../common/grub-legacy.nix
    ../common/zfs
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
    ports = { inherit (config.my.ports.zrepl.yumiko) sink pull; };
    openFirewallForPorts = [ "sink" ];
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/yumiko.m.mado.moe.crt;
    sopsKeyFile = ./zrepl/yumiko.m.mado.moe.key;
  };

  my.services.prometheus.enable = true;
  my.services.tailscale.enable = true;
  my.services.gateway = {
    enable = true;
    internalDomain = "${hostname}.m.mado.moe";
  };
}
