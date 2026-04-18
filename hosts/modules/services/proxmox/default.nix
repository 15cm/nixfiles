{
  config,
  lib,
  mylib,
  inputs,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.services.proxmox;
  inherit (mylib) assertNotNull;
  pveFakeSubscriptionSrc = pkgs.fetchFromGitHub {
    owner = "Jamesits";
    repo = "pve-fake-subscription";
    rev = "v0.0.11";
    hash = "sha256-HP+4Njk0nmEcjfZlNhLQD91+3B54Y3Yc85yWVukpZZI=";
  };
  pveFakeSubscriptionPkg = pkgs.writeShellApplication {
    name = "pve-fake-subscription";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${pveFakeSubscriptionSrc}/usr/bin/pve-fake-subscription "$@"
    '';
  };
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

    fakeSubscription = {
      enable = mkEnableOption "declaratively refresh a fake Proxmox subscription cache to suppress the no-subscription prompt";

      package = mkOption {
        type = types.package;
        default = pveFakeSubscriptionPkg;
        defaultText = literalExpression "pveFakeSubscriptionPkg";
        description = "Package providing the `pve-fake-subscription` executable.";
      };

      blockRemoteChecks = mkOption {
        type = types.bool;
        default = false;
        description = "Add `shop.maurer-it.com` to `/etc/hosts` as localhost to block remote key checks.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Proxmox packages come from the proxmox-nixos overlay.
      nixpkgs.overlays = [ inputs.proxmox-nixos.overlays.x86_64-linux ];

      services.proxmox-ve = {
        enable = true;
        inherit (cfg) ipAddress bridges openFirewall;
      };

      virtualisation.libvirtd = {
        enable = true;
        qemu.vhostUserPackages = [ pkgs.virtiofsd ];
      };

      networking = cfg.networking;

      # proxmox-nixos sets AcceptEnv as a string; NixOS expects list of string.
      services.openssh.settings.AcceptEnv = lib.mkForce [
        "LANG"
        "LC_*"
      ];
    }
    (mkIf cfg.fakeSubscription.enable {
      environment.systemPackages = [ cfg.fakeSubscription.package ];

      networking.extraHosts = mkIf cfg.fakeSubscription.blockRemoteChecks ''
        127.0.0.1 shop.maurer-it.com
      '';

      # Upstream runs the script immediately on install. Mirror that on
      # `nixos-rebuild switch` so the prompt does not linger until the timer fires.
      system.activationScripts.pveFakeSubscription.text = ''
        ${lib.getExe cfg.fakeSubscription.package}
      '';

      systemd.services.pve-fake-subscription = {
        description = "Refresh fake Proxmox subscription cache";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe cfg.fakeSubscription.package;
        };
      };

      systemd.timers.pve-fake-subscription = {
        description = "Refresh fake Proxmox subscription cache every day";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnActiveSec = "0s";
          OnBootSec = "0s";
          OnCalendar = "daily";
          RandomizedDelaySec = "60s";
          Persistent = true;
        };
      };
    })
    (mkIf cfg.enableDashboardProxy {
      services.traefik.staticConfigOptions = {
        accessLog = { };
        log.level = mkForce "DEBUG";
      };

      # Proxmox uploads large ISOs via the web UI. Traefik's default
      # entrypoint read timeout can abort slow uploads before the body finishes.
      services.traefik.staticConfigOptions.entryPoints.websecure.transport.respondingTimeouts.readTimeout =
        0;
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
