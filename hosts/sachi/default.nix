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
    ./samba
  ];

  environment.systemPackages = with pkgs; [ nvidia-container-toolkit ];

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

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "yes";
    };
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.hashedPassword.path;

  boot.kernelPackages = mkForce pkgs.linuxPackages_6_18;
  my.essentials.zfs = {
    enable = true;
    enableNonRootEncryption = true;
    enableZed = true;
    enableZfsUnstable = true;
    nonRootPools = [
      "main"
      "sub"
    ];
    encryptedZfsPath = "main";
  };
  networking = {
    hostName = hostname;
    domain = "mado.moe";
    useDHCP = false;
    defaultGateway = "192.168.88.1";
    # Delegate home firewall to the router.
    firewall.enable = mkForce false;
    interfaces.enp13s0.useDHCP = true;
    # Disable the 1G NIC to make sure the 10G NIC is always used.
    interfaces.eno1.useDHCP = false;
    interfaces.eno2.useDHCP = false;
    interfaces.eno3.useDHCP = false;
    interfaces.eno4.useDHCP = false;
  };
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
  };
  hardware.nvidia-container-toolkit.enable = true;

  boot.kernelModules = [
    "coretemp"
    "kvm-intel"
  ];

  my.services.docker = {
    enable = true;
  };
  my.services.zrepl = {
    enable = true;
    ports = { inherit (config.my.ports.zrepl.sachi) sink source; };
    openFirewallForPorts = [
      "sink"
      "source"
    ];
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/sachi.m.mado.moe.crt;
    sopsKeyFile = ./zrepl/sachi.m.mado.moe.key;
  };

  my.services.gateway = {
    enable = true;
    enableDocker = true;
    internalDomain = "${hostname}.m.mado.moe";
    externalDomain = "mado.moe";
    lanOnlyIpRanges = [
      config.my.ip.ranges.local
      config.my.ip.ranges.lan
      config.my.ip.ranges.wireguard
      config.my.ip.ranges.tailscale
      config.my.ip.ranges.docker
      config.my.ip.ranges.dockerRootless
    ];
  };
  services.traefik.dynamicConfigOptions.http.middlewares = mkIf config.my.services.gateway.enable {
    mastodon-auth-proxy.redirectRegex = {
      permanent = true;
      regex = "^https://mado.moe/\\.well-known/webfinger";
      replacement = "https://mastodon.mado.moe/.well-known/webfinger";
    };
  };
  my.services.headscale.enable = true;
  my.services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };
  my.services.proxmox = {
    enable = true;
    ipAddress = "192.168.88.30";
    bridges = [ "vmbr0" ];
    networking = {
      bridges.vmbr0.interfaces = [ "enp13s0" ];
      interfaces = {
        enp13s0.useDHCP = mkForce false;
        vmbr0 = {
          useDHCP = mkForce true;
          ipv4.addresses = [
            {
              address = "192.168.88.30";
              prefixLength = 24;
            }
          ];
        };
      };
    };
    enableDashboardProxy = true;
  };

  my.services.smartd.enable = true;
  my.services.ups.enable = true;
  my.services.metrics = {
    enable = true;
    enableScrapeHeadscale = true;
    enableScrapeSmartctl = true;
    enableScrapeNut = true;
  };
  my.services.monitoring = {
    enable = true;
    domain = "monitoring.${hostname}.m.mado.moe";
    datasourceHosts = [
      "sachi"
      "kazuki"
      "amane"
      "yumiko"
      "asako"
    ];
    dataDir = "/pool/main/appdata/grafana";
  };
  my.services.aria2 = {
    enable = true;
    package = pkgs.aria2-fast;
    maxConnectionPerServer = 128;
    downloadDir = "/pool/sub/download/aria2";
    enableSession = true;
    enableReverseProxy = true;
  };
  my.programs.AriaNg = {
    enable = true;
    enableReverseProxy = true;
  };
  my.services.vsftpd = {
    enable = true;
    enableSsl = true;
    sopsCertFile = ./ftp/vsftpd.pem;
    sopsKeyFile = ./ftp/vsftpd.key;
  };

  services.udev.extraRules = ''
    # UDEV rules for 3d printer
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2974", ATTRS{idProduct}=="0503", ACTION=="add", MODE:="0660", OWNER:="dockremap", GROUP:="dockremap", SYMLINK+="monoprice_3d_printer"
  '';
}
