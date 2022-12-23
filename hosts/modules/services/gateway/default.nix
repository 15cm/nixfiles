{ config, lib, ... }:

with lib;
let cfg = config.my.services.gateway;
in {
  options.my.services.gateway = { enable = mkEnableOption "traefik gateway"; };

  config = mkIf cfg.enable {
    sops.secrets.traefik-env = {
      format = "binary";
      sopsFile = ./traefik.env.txt;
    };
    services.traefik = {
      enable = true;
      group = "docker";
      staticConfigOptions = {
        log.level = "info";
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
        providers = {
          docker = {
            watch = true;
            endpoint = "unix:///var/run/docker.sock";
            exposedbydefault = false;
            network = "g_proxy";
          };
        };
        certificatesResolvers = {
          default = {
            acme = {
              email = "acme.mado.moe@15cm.net";
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
            secure-internal = {
              chain.middlewares = [ "redirect-to-https" "lan-ipwhitelist" ];
            };
            redirect-to-https.redirectScheme.scheme = "https";
            lan-ipwhitelist.ipWhiteList.sourceRange = [ "10.0.0.0/8" ];
            mastodon-auth-proxy.redirectRegex = {
              permanent = true;
              regex = "^https://mado.moe/\\.well-known/webfinger";
              replacement = "https://mastodon.mado.moe/.well-known/webfinger";
            };
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
  };

}
