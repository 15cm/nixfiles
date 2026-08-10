{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.orca;
  serveArgs = [
    "serve"
    "--port"
    (toString cfg.port)
    "--json"
  ]
  ++ lib.optionals (cfg.pairingAddress != null) [
    "--pairing-address"
    cfg.pairingAddress
  ]
  ++ cfg.extraArgs;
in
{
  options.my.services.orca = {
    enable = lib.mkEnableOption "headless Orca runtime";

    package = lib.mkPackageOption pkgs "orca-ide" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 6768;
      description = "WebSocket port for the Orca runtime.";
    };

    pairingAddress = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = "Address advertised to clients for pairing.";
    };

    extraArgs = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Additional arguments passed to orca serve.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      pkgs.xorg-server
    ];

    systemd.user.services.orca = {
      Unit = {
        Description = "Orca headless runtime server";
        Documentation = "https://github.com/stablyai/orca/blob/main/docs/reference/headless-linux-server.md";
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };

      Service = {
        Type = "simple";
        Environment = [ "LIBGL_ALWAYS_SOFTWARE=1" ];
        ExecStart = "${cfg.package}/bin/orca-ide ${lib.escapeShellArgs serveArgs}";
        Restart = "on-failure";
        RestartPreventExitStatus = 3;
        RestartSec = 5;
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
