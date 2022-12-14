{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports = [
    ./hardware-configuration.nix
    ../common/baseline.nix
    ../common/zfs
    ../common/zfs/encrypted-non-root.nix
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
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    permitRootLogin = "prohibit-password";
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
        # Shadowsocks
        8388
      ];
      allowedUDPPorts = [
        # Coturn
        3478
        5349
        # Shadowsocks
        8388
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
    sopsCertFile = ./zrepl/amane.machine.15cm.net.crt;
    sopsKeyFile = ./zrepl/amane.machine.15cm.net.key;
  };
  my.services.docker = {
    enable = true;
    waitForManualZfsLoadKey = true;
  };
  my.services.docker-rootless = {
    enable = true;
    waitForManualZfsLoadKey = true;
  };
  my.services.shadowsocks-server.enable = true;
}
