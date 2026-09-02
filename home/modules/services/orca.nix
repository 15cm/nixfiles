{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.orca;
  orcaCli = pkgs.writeShellScriptBin "orca" ''
    set -euo pipefail
    export ORCA_NODE_OPTIONS="''${NODE_OPTIONS-}"
    export ORCA_NODE_REPL_EXTERNAL_MODULE="''${NODE_REPL_EXTERNAL_MODULE-}"
    unset NODE_OPTIONS
    unset NODE_REPL_EXTERNAL_MODULE
    ELECTRON_RUN_AS_NODE=1 exec ${lib.getExe pkgs.electron_43} \
      "${cfg.package}/opt/orca-ide/resources/app.asar.unpacked/out/cli/index.js" "$@"
  '';
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
    enable = lib.mkEnableOption "Orca IDE";

    package = lib.mkPackageOption pkgs "orca-ide" { };

    mode = lib.mkOption {
      type = lib.types.enum [
        "gui"
        "headless"
      ];
      default = "headless";
      description = "Whether Orca runs as a GUI or headless runtime server.";
    };

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
    home.file.".local/bin/orca".source = "${orcaCli}/bin/orca";
    programs.zsh.initContent = lib.mkBefore ''
      export ORCA_CLI_COMMAND="orca"
    '';
    home.packages = [ cfg.package orcaCli ] ++ lib.optional (cfg.mode == "headless") pkgs.xorg-server;

    systemd.user.services.orca = lib.mkIf (cfg.mode == "headless") {
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
