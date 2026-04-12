{ config, lib, mylib, pkgs, ... }:

with lib;
let
  cfg = config.my.services.gateway;
  inherit (mylib) mkDefaultTrueEnableOption assertNotNull;
  lanOnlyIpRanges = concatStringsSep " " cfg.lanOnlyIpRanges;
  wanIpRanges =
    concatStringsSep " " (cfg.lanOnlyIpRanges ++ cfg.externalAllowListIpRanges);
  caddyWithCloudflare = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
    hash = "sha256-i7OoxiHJ4Stfp7SnxOryLAXS6w5+PJCnEydOakhFYcE=";
  };
in {
  options.my.services.gateway = {
    enable = mkEnableOption "caddy gateway";
    enableDashboardProxy = mkDefaultTrueEnableOption "gateway status page";
    internalDomain = mkOption {
      type = with types; nullOr str;
      default = null;
      description = "domain for access inside the internal tailscale network";
    };
    externalDomain = mkOption {
      type = with types; nullOr str;
      default = null;
      description = "domain for access over the internet";
    };
    lanOnlyIpRanges = mkOption {
      type = with types; listOf str;
      default = [ config.my.ip.ranges.local ];
    };
    externalAllowListIpRanges = mkOption {
      type = with types; listOf str;
      default = config.my.ip.ranges.cloudFlareList;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      sops.secrets.caddyCloudflareApiToken = {
        sopsFile = ../../../common/secrets.yaml;
        owner = config.services.caddy.user;
      };
      sops.templates."caddy-cloudflare.env" = {
        content = ''
          CLOUDFLARE_API_TOKEN=${config.sops.placeholder.caddyCloudflareApiToken}
        '';
        owner = config.services.caddy.user;
        group = config.services.caddy.group;
      };

      services.caddy = {
        enable = true;
        package = caddyWithCloudflare;
        email = "acme@15cm.net";
        environmentFile = config.sops.templates."caddy-cloudflare.env".path;
        logFormat = mkForce ''
          level INFO
        '';
        openFirewall = true;
        globalConfig = ''
          acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        '';
        extraConfig = ''
          (lan-only) {
            @denied not remote_ip ${lanOnlyIpRanges}
            respond @denied "Forbidden" 403
          }

          (wan-only) {
            @denied not remote_ip ${wanIpRanges}
            respond @denied "Forbidden" 403
          }
        '';
      };
    }
    (mkIf cfg.enableDashboardProxy {
      services.caddy.virtualHosts."gateway.${assertNotNull cfg.internalDomain}" = {
        extraConfig = ''
          import lan-only
          respond "Caddy gateway active"
        '';
      };
    })
  ]);

}
