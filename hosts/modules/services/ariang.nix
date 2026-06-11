{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:

with lib;
let
  cfg = config.my.services.ariang;
in
{
  options.my.services.ariang = {
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
      systemd.services.ariang = {
        description = "AriaNg web UI";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = ''
            ${pkgs.static-web-server}/bin/static-web-server \
              --host 127.0.0.1 \
              --port ${toString cfg.port} \
              --root ${pkgs.AriaNg}/share/AriaNg
          '';
          DynamicUser = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          Restart = "on-failure";
        };
      };
    }
    (mkIf (cfg.enableReverseProxy && config.my.services.gateway.enable) {
      services.traefik.dynamicConfigOptions.http.routers.ariang = {
        rule = "Host(`${cfg.hostName}`)";
        middlewares = [ "lan-only@file" ];
        service = "ariang";
      };
      services.traefik.dynamicConfigOptions.http.services.ariang.loadBalancer.servers = [
        {
          url = "http://127.0.0.1:${toString cfg.port}";
        }
      ];
    })
  ]);
}
