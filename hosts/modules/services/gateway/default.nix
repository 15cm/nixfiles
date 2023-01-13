{ config, lib, mylib, ... }:

with lib;
let
  cfg = config.my.services.gateway;
  inherit (mylib) mkDefaultTrueEnableOption assertNotNull;
in {
  options.my.services.gateway = {
    enable = mkEnableOption "traefik gateway";
    enableDocker = mkEnableOption "docker integration";
    enableDashboardProxy = mkDefaultTrueEnableOption "dashboard proxy";
    enableHeadscaleProxy = mkEnableOption "headscale proxy";
    enablePrometheusProxy = mkDefaultTrueEnableOption "prometheus proxy";
    internalDomain = mkOption {
      type = with types; nullOr string;
      default = null;
      description = "domain for access inside the internal tailscale network";
    };
    externalDomain = mkOption {
      type = with types; nullOr string;
      default = null;
      description = "domain for access over the internet";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      networking.firewall.allowedTCPPorts = [ 80 443 ];
      sops.secrets.traefik-env = {
        format = "binary";
        sopsFile = ./traefik.env.txt;
      };
      services.traefik = {
        enable = true;
        staticConfigOptions = {
          log.level = "debug";
          api = {
            dashboard = true;
            insecure = true;
          };
          entryPoints = {
            web = {
              address = ":80";
              http.redirections.entryPoint = {
                to = "websecure";
                scheme = "https";
                permanent = false;
              };
            };
            websecure = {
              address = ":443";
              http.tls.certResolver = "default";
            };
          };
          certificatesResolvers = {
            default = {
              acme = {
                email = "acme@15cm.net";
                storage = "${config.services.traefik.dataDir}/acme.json";
                dnsChallenge = {
                  provider = "cloudflare";
                  delayBeforeCheck = 5;
                  resolvers = [ "1.1.1.1:53" "8.8.8.8:53" ];
                };
              };
            };
          };
        };
        dynamicConfigOptions = {
          http = {
            middlewares = {
              lan-only.ipWhiteList.sourceRange = [
                config.my.ip.ranges.lan
                config.my.ip.ranges.wireguard
                config.my.ip.ranges.tailscale
              ];
            };
          };
        };
      };

      systemd.services.traefik = {
        serviceConfig = {
          EnvironmentFile = config.sops.secrets.traefik-env.path;
        };
      };
      users.users.traefik = { uid = config.my.ids.uids.traefik; };
      users.groups.traefik.gid = config.my.ids.uids.traefik;
    }
    (mkIf cfg.enableDocker {
      services.traefik.staticConfigOptions.providers = {
        services.traefik.group = "docker";
        docker = {
          watch = true;
          endpoint = "unix:///var/run/docker.sock";
          exposedbydefault = false;
          network = "g_proxy";
        };
      };
    })
    (mkIf cfg.enableDashboardProxy {
      services.traefik.dynamicConfigOptions.http = {
        routers.gatewayApi = {
          rule = "Host(`gateway.${assertNotNull cfg.internalDomain}`)";
          middlewares = [ "lan-only@file" ];
          service = "gatewayApi";
        };
        services = {
          gatewayApi.loadBalancer.servers = [{
            url = "http://localhost:${toString config.my.ports.gateway.listen}";
          }];
        };
      };
    })
    (mkIf cfg.enableHeadscaleProxy {
      services.traefik.dynamicConfigOptions.http = {
        routers.headscale = {
          rule = "Host(`headscale.${assertNotNull cfg.externalDomain}`)";
          service = "headscale";
        };
        services = {
          headscale.loadBalancer.servers = [{
            url =
              "http://localhost:${toString config.my.ports.headscale.listen}";
          }];
        };
      };
    })
    (mkIf cfg.enablePrometheusProxy {
      services.traefik.dynamicConfigOptions.http = {
        routers.prometheus = {
          rule = "Host(`metrics.${assertNotNull cfg.internalDomain}`)";
          middlewares = [ "lan-only@file" ];
          service = "prometheus";
        };
        services = {
          prometheus.loadBalancer.servers = [{
            url =
              "http://localhost:${toString config.my.ports.prometheus.listen}";
          }];
        };
      };
    })
  ]);

}
