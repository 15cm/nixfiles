{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.openrgb;
in {
  options.my.services.openrgb = {
    enable = mkEnableOption "OpenRGB";
    package = mkPackageOption pkgs "openrgb" { };
    server.port = mkOption {
      type = types.port;
      default = 6742;
      description = "Set server port of openrgb.";
    };
  };

  config = mkIf cfg.enable {
    boot.kernelModules = [
      # Ensure we can access i2c bus for RGB memory
      "i2c-dev"
      "i2c-piix4"
    ];
    systemd.services.openrgb = {
      description = "OpenRGB server daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        StateDirectory = "OpenRGB";
        WorkingDirectory = "/var/lib/OpenRGB";
        ExecStart = "${cfg.package}/bin/openrgb --server --server-port ${
            toString cfg.server.port
          } -p default";
        Restart = "always";
      };
    };
  };
}
