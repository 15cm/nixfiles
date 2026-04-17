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
    }
    (mkIf cfg.enableDashboardProxy {
      services.traefik.dynamicConfigOptions.http = {
        routers.proxmox = {
          rule = "Host(`vm.${assertNotNull config.my.services.gateway.internalDomain}`)";
          middlewares = [ "lan-only@file" ];
          service = "proxmox";
        };
        services.proxmox.loadBalancer.servers = [ { url = "http://127.0.0.1:8006"; } ];
      };
    })
  ]);
}
