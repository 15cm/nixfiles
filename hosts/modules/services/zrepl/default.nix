{ config, lib, mylib, ... }:

with lib;
let
  inherit (mylib) templateFile;
  cfg = config.my.services.zrepl;
  templateData = {
    caCertFile = cfg.caCertFile;
    certFile = config.sops.secrets.zrepl-cert.path;
    keyFile = config.sops.secrets.zrepl-key.path;
    port = cfg.port;
  };

in {
  options.my.services.zrepl = {
    enable = mkEnableOption "zrepl";
    configTemplateFile = mkOption {
      default = null;
      type = with types; nullOr path;
    };
    sopsCertFile = mkOption {
      default = null;
      type = with types; nullOr path;
    };
    sopsKeyFile = mkOption {
      default = null;
      type = with types; nullOr path;
    };

    port = mkOption {
      default = 38888;
      type = types.int;
    };
    openFirewall = mkEnableOption "open zrepl port";
    caCertFile = mkOption {
      default = ./zrepl-ca.crt;
      type = types.path;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      zrepl-cert = {
        format = "binary";
        sopsFile = (assert cfg.sopsCertFile != null; cfg.sopsCertFile);
      };
      zrepl-key = {
        format = "binary";
        sopsFile = (assert cfg.sopsKeyFile != null; cfg.sopsKeyFile);
      };
    };
    services.my.zrepl = {
      enable = true;
      configFile = templateFile "zrepl-config" templateData
        (assert cfg.configTemplateFile != null; cfg.configTemplateFile);
    };
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
