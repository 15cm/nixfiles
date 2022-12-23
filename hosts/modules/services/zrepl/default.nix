{ config, lib, mylib, ... }:

with lib;
let
  inherit (mylib) templateFile;
  cfg = config.my.services.zrepl;
  templateData = {
    inherit (cfg) caCertFile ports;
    certFile = config.sops.secrets.zrepl-cert.path;
    keyFile = config.sops.secrets.zrepl-key.path;
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

    ports = mkOption {
      default = {
        sink = 38888;
        source = 38889;
      };
      type = with types; attrsOf int;
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
    networking.firewall.allowedTCPPorts =
      mkIf cfg.openFirewall (attrValues cfg.ports);
  };
}
