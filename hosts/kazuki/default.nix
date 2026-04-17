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
    ../common/boot-loader.nix
    ../common/users.nix
    ../common/trusted.nix
  ];

  environment.systemPackages = with pkgs; [
    easyrsa
    i2c-tools
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      hashedPassword.neededForUsers = true;
    };
    age = {
      keyFile = "/keys/age/${hostname}.txt";
      sshKeyPaths = [ ];
    };
    # https://github.com/Mic92/sops-nix/issues/167
    gnupg.sshKeyPaths = [ ];
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.hashedPassword.path;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  boot.kernelPackages = mkForce pkgs.linuxPackages_6_18;
  my.essentials.zfs = {
    enable = true;
    enableZed = true;
    enableZfsUnstable = true;
    arcMaxBytes = 12 * 1024 * 1024 * 1024;
  };
  my.essentials.gui.enable = true;

  networking = {
    hostName = hostname;
    domain = "mado.moe";
    networkmanager = {
      enable = false;
    };
    useDHCP = false;
    defaultGateway = "192.168.88.1";
    interfaces.enp22s0.useDHCP = true;
    firewall.enable = mkForce false;
  };

  my.services.proxmox = {
    enable = true;
    ipAddress = "192.168.88.29";
    bridges = [ "vmbr0" ];
    networking = {
      bridges.vmbr0.interfaces = [ "enp22s0" ];
      interfaces = {
        enp22s0.useDHCP = mkForce false;
        vmbr0 = {
          useDHCP = mkForce true;
          ipv4.addresses = [
            {
              address = "192.168.88.29";
              prefixLength = 24;
            }
          ];
        };
      };
    };
    enableDashboardProxy = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
  };

  boot.kernelParams = [
    "acpi_enforce_resources=lax"
    "transparent_hugepage=never"
  ];
  hardware = {
    i2c = {
      enable = true;
    };
  };
  services.fwupd.enable = true;

  my.services.zrepl = {
    enable = true;
    ports = { inherit (config.my.ports.zrepl.kazuki) push; };
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/kazuki.m.mado.moe.crt;
    sopsKeyFile = ./zrepl/kazuki.m.mado.moe.key;
  };

  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  my.services.aria2 = {
    package = pkgs.aria2-fast;
    maxConnectionPerServer = 128;
  };
  hardware.graphics.enable32Bit = true;

  my.services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
  my.services.gateway = {
    enable = true;
    enableDocker = true;
    internalDomain = "${hostname}.m.mado.moe";
    lanOnlyIpRanges = [
      config.my.ip.ranges.local
      config.my.ip.ranges.lan
      config.my.ip.ranges.wireguard
      config.my.ip.ranges.tailscale
    ];
  };
  my.services.shadowsocks-client = {
    enable = true;
    serverAddress = "direct.15cm.net";
  };

  my.services.smartd.enable = true;
  my.services.metrics = {
    enable = true;
    enableScrapeSmartctl = true;
  };
}
