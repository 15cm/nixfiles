{ config, lib, pkgs, mylib, ... }:

with lib;
let
  cfg = config.my.services.aria2;
  inherit (mylib) templateFile assertNotNull;
  templateData = { inherit (cfg) downloadDir; };
  aria2Config = templateFile "aria2-conf" templateData ./aria2.conf.jinja;
  sessionFile = "${cfg.programDir}/aria2.session";
in {
  options.my.services.aria2 = {
    enable = mkEnableOption "Aria2";
    package = mkOption {
      type = types.package;
      default = pkgs.aria2;
    };
    user = mkOption {
      type = types.str;
      default = "sinkerine";
    };
    downloadDir = mkOption {
      type = types.str;
      default = "/home/${cfg.user}/Donwloads";
    };
    programDir = mkOption {
      type = types.str;
      default = "/home/${cfg.user}/.local/share/aria2";
    };
    enableSession = mkEnableOption "Session file";
    enableReverseProxy = mkEnableOption "Reverse proxy";
  };
  config = mkIf cfg.enable (mkMerge [
    {
      sops.secrets.aria2-env = {
        format = "binary";
        sopsFile = ./aria2.env.txt;
      };

      systemd.services.aria2 = {
        description = "Aria2 Service";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          EnvironmentFile = [ config.sops.secrets.aria2-env.path ];
          ExecStart = pkgs.writeShellScript "aria2-wrapper"
            (concatStringsSep " " ([
              "${cfg.package}/bin/aria2c"
              "--conf-path=${aria2Config}"
              "--rpc-secret=$ARIA2_RPC_SECERT"
            ] ++ (optionals cfg.enableSession [
              "--input-file=${sessionFile}"
              "--save-session=${sessionFile}"
              "--save-session-interval=60"
            ])));
          ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
          User = "${cfg.user}";
          Group = "${cfg.user}";
          Restart = "on-abort";
        };
      };
    }
    (mkIf cfg.enableSession {
      systemd.services.aria2.preStart = ''
        mkdir -p ${cfg.programDir}
        if [[ ! -e "${sessionFile}" ]]; then touch "${sessionFile}"; fi
        chown -R ${cfg.user}:${cfg.user} ${cfg.programDir}
      '';
    })
    (mkIf cfg.enableReverseProxy {
      services.traefik.dynamicConfigOptions.http = {
        routers.aria2 = {
          rule = "Host(`aria2.${
              assertNotNull config.my.services.gateway.internalDomain
            }`)";
          middlewares = [ "lan-only@file" ];
          service = "aria2";
        };
        services = {
          aria2.loadBalancer.servers = [{
            url = "http://127.0.0.1:${toString config.my.ports.aria2.listen}";
          }];
        };
      };
    })
  ]);
}
