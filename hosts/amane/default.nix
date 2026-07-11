{
  config,
  pkgs,
  lib,
  mylib,
  hostname,
  ...
}:

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
    secrets = {
      hashedPassword.neededForUsers = true;
      v2rayClientId = {
        owner = "v2ray";
        group = "v2ray";
      };
    };
    templates."v2ray.json" = {
      owner = "v2ray";
      group = "v2ray";
      content = builtins.toJSON {
        log.loglevel = "warning";
        inbounds = [
          {
            listen = "0.0.0.0";
            port = config.my.ports.v2ray.listen;
            protocol = "vmess";
            settings.clients = [
              {
                id = config.sops.placeholder.v2rayClientId;
                alterId = 0;
              }
            ];
            streamSettings.network = "tcp";
          }
        ];
        outbounds = [
          {
            protocol = "freedom";
          }
        ];
      };
      restartUnits = [ "v2ray.service" ];
    };
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

  environment.systemPackages = with pkgs; [ v2ray ];

  boot.kernelPackages = mkForce pkgs.linuxPackages_6_18;
  my.essentials.zfs = {
    enable = true;
    enableNonRootEncryption = true;
    enableZed = true;
    enableZfsUnstable = true;
    nonRootPools = [ "tank" ];
    encryptedZfsPath = "tank/encrypted";
  };

  networking = {
    hostName = hostname;
    domain = "15cm.net";
    useDHCP = true;
    firewall = {
      allowedTCPPorts = [
        config.my.ports.v2ray.listen
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

  nix.gc.options = mkForce "-d";

  my.services.zrepl = {
    enable = true;
    ports = { inherit (config.my.ports.zrepl.amane) push; };
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/amane.m.mado.moe.crt;
    sopsKeyFile = ./zrepl/amane.m.mado.moe.key;
  };
  my.services.docker = {
    enable = true;
  };
  my.services.metrics.enable = true;
  my.services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };
  users.users.v2ray = {
    group = "v2ray";
    isSystemUser = true;
  };
  users.groups.v2ray = { };
  services.v2ray = {
    enable = true;
    configFile = config.sops.templates."v2ray.json".path;
  };
  systemd.services.v2ray.serviceConfig = {
    DynamicUser = mkForce false;
    User = "v2ray";
    Group = "v2ray";
  };
  my.services.gateway = {
    enable = true;
    enableDocker = true;
    internalDomain = "${hostname}.m.mado.moe";
    lanOnlyIpRanges = [
      config.my.ip.ranges.local
      config.my.ip.ranges.tailscale
    ];
  };
}
