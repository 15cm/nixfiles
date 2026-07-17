{
  config,
  pkgs,
  lib,
  mylib,
  hostname,
  ...
}:

with lib;

let
  wanIf = "enp13s0";
  brIf = "vmbr0";

  hostIp = "192.168.88.30/24";
  gateway = "192.168.88.1";

  dockerServiceInit = pkgs.writeShellApplication {
    name = "docker-service-init";
    runtimeInputs = [
      config.boot.zfs.package
      pkgs.coreutils
    ];
    text = ''
      if [[ $# -ne 1 || ! $1 =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        echo "usage: docker-service-init <service>" >&2
        exit 2
      fi

      service=$1
      dataset="main/docker/available/$service"
      mountpoint="/pool/main/docker/available/$service"

      if zfs list -H -o name "$dataset" >/dev/null 2>&1; then
        echo "refusing existing dataset: $dataset" >&2
        exit 1
      fi

      created=false
      cleanup() {
        status=$?
        if [[ $status -ne 0 && $created == true ]]; then
          zfs destroy "$dataset" || true
        fi
        exit "$status"
      }
      trap cleanup EXIT

      zfs create "$dataset"
      created=true
      chown sinkerine:sinkerine "$mountpoint"
      created=false
      trap - EXIT

      echo "created $dataset at $mountpoint"
    '';
  };
in
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

  environment.systemPackages = with pkgs; [
    deploy-rs
    dockerServiceInit
    nvidia-container-toolkit
    v2ray
  ];

  security.sudo.extraRules = [
    {
      users = [ "sinkerine" ];
      commands = [
        {
          command = "${dockerServiceInit}/bin/docker-service-init";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      hashedPassword.neededForUsers = true;
      v2rayClientId = {
        owner = "v2ray";
        group = "v2ray";
      };
      v2raySniClientId = {
        owner = "v2ray";
        group = "v2ray";
      };
      v2rayTlsCert = {
        format = "binary";
        sopsFile = ./zrepl/sachi.m.mado.moe.crt;
        owner = "v2ray";
        group = "v2ray";
      };
      v2rayTlsKey = {
        format = "binary";
        sopsFile = ./zrepl/sachi.m.mado.moe.key;
        owner = "v2ray";
        group = "v2ray";
      };
    };
    templates."v2ray.json" = {
      owner = "v2ray";
      group = "v2ray";
      content =
        let
          vmessClient = {
            id = config.sops.placeholder.v2rayClientId;
            alterId = 0;
          };
          vmessSniClient = {
            id = config.sops.placeholder.v2raySniClientId;
            alterId = 0;
          };
        in
        builtins.toJSON {
          log.loglevel = "warning";
          inbounds = [
            {
              listen = "0.0.0.0";
              port = config.my.ports.v2ray.listen;
              protocol = "vmess";
              settings.clients = [ vmessClient ];
              streamSettings.network = "tcp";
            }
            {
              listen = "0.0.0.0";
              port = config.my.ports.v2ray.listenTls;
              protocol = "vmess";
              settings.clients = [ vmessSniClient ];
              streamSettings = {
                network = "tcp";
                security = "tls";
                tlsSettings = {
                  serverName = "google-analytics.com";
                  certificates = [
                    {
                      certificateFile = config.sops.secrets.v2rayTlsCert.path;
                      keyFile = config.sops.secrets.v2rayTlsKey.path;
                    }
                  ];
                };
              };
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
  networking.useDHCP = false;
  networking.networkmanager.enable = false;
  networking.firewall.enable = mkForce false;

  systemd.network.enable = true;

  # Bridged traffic does not need bridge netfilter on this host and the
  # extra hooks noticeably slow large LAN transfers such as SMB mounts.
  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
    "net.bridge.bridge-nf-call-arptables" = 0;
  };

  systemd.network.netdevs."10-${brIf}" = {
    netdevConfig = {
      Name = brIf;
      Kind = "bridge";
    };
    bridgeConfig = {
      STP = false;
      ForwardDelaySec = 0;
    };
  };

  systemd.network.networks."10-${wanIf}" = {
    matchConfig.Name = wanIf;
    networkConfig = {
      Bridge = brIf;
      DHCP = "no";
      LinkLocalAddressing = "no";
      IPv6AcceptRA = false;
    };
  };

  systemd.network.networks."20-${brIf}" = {
    matchConfig.Name = brIf;
    address = [ hostIp ];
    networkConfig = {
      DHCP = "no";
      DNS = [ gateway ];
      IPv6AcceptRA = false;
      LinkLocalAddressing = "ipv6";
    };
    routes = [
      {
        Gateway = gateway;
        GatewayOnLink = true;
      }
    ];
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
  networking.firewall.allowedTCPPorts = with config.my.ports.v2ray; [
    listen
    listenTls
  ];
  my.services.proxmox = {
    enable = true;
    ipAddress = "192.168.88.30";
    bridges = [ "vmbr0" ];
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
  my.services.ariang = {
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
