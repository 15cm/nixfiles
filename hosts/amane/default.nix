{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports = [
    ./hardware-configuration.nix
    ../common/baseline.nix
    ../common/users.nix
    ../common/grub-legacy.nix
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
    enableNonRootEncryption = true;
    enableZed = true;
    nonRootPools = [ "tank" ];
    encryptedZfsPath = "tank/encrypted";
  };

  networking = {
    hostName = hostname;
    domain = "15cm.net";
    useDHCP = true;
    firewall = {
      allowedTCPPorts = [
        # Coturn
        3478
        5349
      ];
      allowedUDPPorts = [
        # Coturn
        3478
        5349
      ];
      allowedUDPPortRanges = [
        # Coturn
        {
          from = 49160;
          to = 49200;
        }
      ];
    };
  };

  my.services.zrepl = {
    enable = true;
    ports = { inherit (config.my.ports.zrepl.amane) push; };
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/amane.m.mado.moe.crt;
    sopsKeyFile = ./zrepl/amane.m.mado.moe.key;
  };
  my.services.docker = { enable = true; };
  my.services.shadowsocks-server.enable = true;

  my.services.metrics.enable = true;
  my.services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };
  my.services.gateway = {
    enable = true;
    enableDocker = true;
    internalDomain = "${hostname}.m.mado.moe";
    lanOnlyIpRanges =
      [ config.my.ip.ranges.local config.my.ip.ranges.tailscale ];
  };
}
