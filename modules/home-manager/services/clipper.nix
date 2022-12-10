{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.clipper;
  clipperCfg = config.programs.clipper;
  clipperBinary = "${cfg.package}/bin/clipper";
  preStartScript = pkgs.writeShellScript "clipper-pre-start" ''
    mkdir -p ${cfg.logDir}
  '';
in {
  meta.maintainers = [ "i@15cm.net" ];

  options.services.clipper = {
    enable = mkEnableOption "the clipper daemon";
    package = mkOption {
      type = types.package;
      default = clipperCfg.package;
      description = "The Clipper package to use.";
    };

    extraArgs = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "-p" "8378" ];
      description = ''
        Extra command-line arguments to pass to <command>clipper</command>.
      '';
    };

    logDir = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        The dir that contains the log file. Will be created before the service starts.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [{
    assertions = [
      (lib.hm.assertions.assertPlatform "services.clipper" pkgs
        lib.platforms.linux)
    ];
    systemd.user.services.clipper = {
      Unit = {
        Description = "Clipper ~ Clipboard proxy";
        Documentation = "https://github.com/wincent/clipper";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStartPre = "${preStartScript}";
        ExecStart = "${clipperBinary} ${escapeShellArgs cfg.extraArgs}";
        Restart = "on-failure";
        RestartSec = 10;
        SyslogIdentifier = "clipper";
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  }]);
}
