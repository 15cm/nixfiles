{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports = [
    ./hardware-configuration.nix
    ../common/baseline.nix
    ../common/grub-legacy.nix
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
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  boot.kernelPackages = mkForce pkgs.linuxPackages_6_6;
  my.essentials.zfs = {
    enable = true;
    enableZed = true;
    nonRootPools = [ "tank" ];
  };
  boot.zfs.requestEncryptionCredentials = false;

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

  my.services.metrics.enable = true;
  my.services.tailscale.enable = true;
  my.services.gateway = {
    enable = true;
    internalDomain = "${hostname}.m.mado.moe";
    lanOnlyIpRanges =
      [ config.my.ip.ranges.local config.my.ip.ranges.tailscale ];
  };
}
