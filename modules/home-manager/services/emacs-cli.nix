{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.emacs-cli;
  emacsCfg = config.programs.emacs;
in {
  meta.maintainers = [ "i@15cm.net" ];

  options.services.emacs-cli = {
    enable = mkEnableOption "the Emacs daemon";

    package = mkOption {
      type = types.package;
      default = (assert emacsCfg.enable; emacsCfg.finalPackage);
      defaultText = literalExpression ''
        if config.programs.emacs.enable then config.programs.emacs.finalPackage
        else pkgs.emacs
      '';
      description = "The Emacs package to use.";
    };

    socketPath = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    extraOptions = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "-f" "exwm-enable" ];
      description = ''
        Extra command-line arguments to pass to <command>emacs</command>.
      '';
    };

    startWithUserSession = lib.mkOption {
      type = lib.types.bool;
      default = !cfg.socketActivation.enable;
      defaultText =
        literalExpression "!config.services.emacs-misc.socketActivation.enable";
      example = true;
      description = ''
        Whether to launch Emacs service with the systemd user session.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [{
    assertions = [
      (lib.hm.assertions.assertPlatform "services.emacs-cli" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.emacs-cli = {
      Unit = {
        Description = "Emacs text editor";
        Documentation =
          "info:emacs man:emacs(1) https://gnu.org/software/emacs/";
      };
      Service = {
        ExecStart = "${cfg.package}/bin/emacs --fg-daemon=${
            assert cfg.socketPath != null;
            cfg.socketPath
          }";
        # Emacs will exit with status 15 after having received SIGTERM, which
        # is the default "KillSignal" value systemd uses to stop services.
        SuccessExitStatus = 15;
        Restart = "on-failure";
      };
    } // optionalAttrs (cfg.startWithUserSession) {
      Install = { WantedBy = [ "default.target" ]; };
    };
  }]);
}
