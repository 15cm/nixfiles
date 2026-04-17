{
  config,
  lib,
  mylib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.my.services.proxmox;
  inherit (mylib) assertNotNull;
in
{
  # Always import to register services.proxmox-ve options.
  imports = [ inputs.proxmox-nixos.nixosModules.proxmox-ve ];

  options.my.services.proxmox = {
    enable = mkEnableOption "Proxmox VE";

    ipAddress = mkOption {
      type = types.str;
      description = "Host IP added to /etc/hosts as <ip> <hostname>, used by Proxmox internal services for node resolution.";
      example = "192.168.1.10";
    };

    bridges = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Linux or OVS bridges visible in the Proxmox web interface.";
    };

    networking = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional `networking` configuration applied when Proxmox is enabled.";
      example = {
        bridges.vmbr0.interfaces = [ "enp1s0" ];
        interfaces = {
          enp1s0.useDHCP = false;
          vmbr0.useDHCP = true;
        };
      };
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open firewall ports for Proxmox web UI (8006), rpcbind (111), and HTTP/HTTPS.";
    };

    enableDashboardProxy = mkEnableOption "Proxmox dashboard reverse proxy via gateway";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Proxmox packages come from the proxmox-nixos overlay.
      nixpkgs.overlays = [ inputs.proxmox-nixos.overlays.x86_64-linux ];

      services.proxmox-ve = {
        enable = true;
        inherit (cfg) ipAddress bridges openFirewall;
      };

      networking = cfg.networking;

      # Bridged traffic does not need bridge netfilter on this host and the
      # extra hooks noticeably slow large LAN transfers such as SMB mounts.
      boot.kernel.sysctl = {
        "net.bridge.bridge-nf-call-iptables" = 0;
        "net.bridge.bridge-nf-call-ip6tables" = 0;
        "net.bridge.bridge-nf-call-arptables" = 0;
      };

      # proxmox-nixos sets AcceptEnv as a string; NixOS expects list of string.
      services.openssh.settings.AcceptEnv = lib.mkForce [ "LANG" "LC_*" ];
    }
    (mkIf cfg.enableDashboardProxy {
      services.traefik.staticConfigOptions = {
        accessLog = { };
        log.level = mkForce "DEBUG";
      };

      # Proxmox uploads large ISOs via the web UI. Traefik's default
      # entrypoint read timeout can abort slow uploads before the body finishes.
      services.traefik.staticConfigOptions.entryPoints.websecure.transport.respondingTimeouts.readTimeout = 0;
      services.traefik.dynamicConfigOptions.http = {
        routers.proxmox = {
          rule = "Host(`vm.${assertNotNull config.my.services.gateway.internalDomain}`)";
          middlewares = [ "lan-only@file" ];
          service = "proxmox";
        };
        services.proxmox.loadBalancer = {
          servers = [ { url = "https://127.0.0.1:8006"; } ];
          passHostHeader = true;
          serversTransport = "proxmox";
        };
        serversTransports.proxmox = {
          insecureSkipVerify = true;
          disableHTTP2 = true;
        };
      };
    })
  ]);
}
