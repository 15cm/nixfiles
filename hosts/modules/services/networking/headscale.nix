{ config, lib, mylib, ... }:

with lib;
let
  cfg = config.my.services.headscale;
  inherit (mylib) assertNotNull;
in {
  options.my.services.headscale = { enable = mkEnableOption "headscale"; };

  config = mkIf cfg.enable {
    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = config.my.ports.headscale.listen;
      settings = {
        server_url = "https://headscale.mado.moe";
        metrics_listen_addr =
          "127.0.0.1:${toString config.my.ports.prometheus.headscale}";
        ip_prefixes = [ "fd7a:115c:a1e0::/48" config.my.ip.ranges.tailscale ];
        dns.magic_dns = false;
        override_local_dns = false;
      };
    };

    services.traefik.dynamicConfigOptions.http = {
      routers.headscale = {
        rule = "Host(`headscale.${
            assertNotNull config.my.services.gateway.externalDomain
          }`)";
        service = "headscale";
      };
      services = {
        headscale.loadBalancer.servers = [{
          url = "http://127.0.0.1:${toString config.my.ports.headscale.listen}";
        }];
      };
    };
  };
}
