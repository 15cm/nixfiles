{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.my.clipper;
  preStartScript = pkgs.writeShellScript "clipper-pre-start" ''
    mkdir -p ${cfg.logDir}
  '';
  configFile =
    pipe cfg.settings [ builtins.toJSON (builtins.toFile "clipper-config") ];
in {
  meta.maintainers = [ "i@15cm.net" ];

  options.services.my.clipper = {
    enable = mkEnableOption "the clipper daemon";
    package = mkOption {
      type = types.package;
      default = pkgs.clipper;
      defaultText = literalExpression "pkgs.clipper";
      description = "The clipper package to install.";
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

    settings = mkOption {
      type = types.attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable (mkMerge [{
    assertions = [
      (lib.hm.assertions.assertPlatform "services.my.clipper" pkgs
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
        ExecStartPre = "{preStartScript}";
        ExecStart = concatStringsSep " " [
          "${cfg.package}/bin/clipper"
          (escapeShellArgs cfg.extraArgs)
          "-c ${configFile}"
        ];
        Restart = "on-failure";
        RestartSec = 10;
        SyslogIdentifier = "clipper";
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  }]);
}
