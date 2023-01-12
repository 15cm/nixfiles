{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.clipper;
in {
  options.my.services.clipper = {
    enable = mkEnableOption "clipper";
    port = mkOption {
      type = types.int;
      default = 8377;
    };
    address = mkOption {
      type = types.str;
      default = "localhost";
    };
    copyCommand = mkOption {
      type = types.str;
      readOnly = true;
      default = concatStringsSep " " ([ "nc" ]
        ++ optionals pkgs.stdenv.isLinux [ "-N" ]
        ++ [ cfg.address (toString cfg.port) ]);
    };
    logDir = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/local/log";
    };
    logFileName = mkOption {
      type = types.str;
      default = "clipper.log";
    };
    logFile = mkOption {
      readOnly = true;
      type = types.path;
      default = "${cfg.logDir}/${cfg.logFileName}";
    };
    extraSettings = mkOption {
      type = types.attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    services.my.clipper = {
      enable = true;
      settings = {
        inherit (cfg) address port;
        logfile = cfg.logFile;
      };
      inherit (cfg) logDir;
    };
  };
}
