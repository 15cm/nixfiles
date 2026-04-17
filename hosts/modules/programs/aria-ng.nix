{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:

with lib;
let
  cfg = config.my.programs.AriaNg;
in
{
  options.my.programs.AriaNg = {
    enable = mkEnableOption "AriaNg";
    enableReverseProxy = mkEnableOption "AriaNg reverse proxy";
    port = mkOption {
      type = types.int;
      default = 3001;
    };
    hostName = mkOption {
      type = types.str;
      default = "ariang.${hostname}.m.mado.moe";
      description = "Internal hostname exposed through traefik.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.nginx.enable = true;
      services.nginx.virtualHosts.ariang = {
        root = "${pkgs.AriaNg}/share/AriaNg";
        serverName = "_";
        default = true;
        listen = [
          {
            addr = "localhost";
            port = cfg.port;
          }
        ];
      };
    }
    (mkIf (cfg.enableReverseProxy && config.my.services.gateway.enable) {
      services.traefik.dynamicConfigOptions.http = {
        routers.ariang = {
          rule = "Host(`${cfg.hostName}`)";
          middlewares = [ "lan-only@file" ];
          service = "ariang";
        };
        services.ariang.loadBalancer.servers = [
          {
            url = "http://127.0.0.1:${toString cfg.port}";
          }
        ];
      };
    })
  ]);
}
