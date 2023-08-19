{ config, pkgs, lib, mylib, ... }:

with lib;
let
  inherit (mylib) templateFile;
  cfg = config.my.services.zrepl;
  templateData = {
    inherit (cfg) caCertFile ports;
    certFile = config.sops.secrets.zrepl-cert.path;
    keyFile = config.sops.secrets.zrepl-key.path;
    monitoringPort = config.my.ports.prometheus.zrepl;
  };
  configFile = mkForce (templateFile "zrepl-config" templateData
    (assert cfg.configTemplateFile != null; cfg.configTemplateFile));

in {
  options.my.services.zrepl = {
    enable = mkEnableOption "zrepl";
    package = mkOption {
      type = types.package;
      default = pkgs.zrepl;
    };
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
      default = { };
      type = with types; attrsOf int;
      example = literalExpression ''
        {
          sink = 38888;
          source = 38889;
        }
      '';
    };
    openFirewallForPorts = mkOption {
      default = [ ];
      type = with types; listOf str;
      description = "List of port names to open firewall for.";
    };
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
    environment.systemPackages = [ cfg.package ];
    systemd.packages = [ cfg.package ];
    systemd.services.zrepl = {
      # Fork the official zrepl module. Remove the `requires` which causes zrepl.service to always restart on NixOS switch. Pass in the config file genereated from jinja template.
      wantedBy = [ "zfs.target" ];
      after = [ "zfs.target" ];
      path = [ config.boot.zfs.package ];
      restartTriggers = [ configFile ];
    };
    environment.etc."zrepl/zrepl.yml".source = configFile;
    networking.firewall.allowedTCPPorts =
      attrVals cfg.openFirewallForPorts cfg.ports;
  };
}
