{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.services.openrgb;
  no-rgb = pkgs.writeScriptBin "no-rgb" ''
    #!/bin/sh
    NUM_DEVICES=$(${pkgs.openrgb}/bin/openrgb --noautoconnect --list-devices | grep -E '^[0-9]+: ' | wc -l)

    for i in $(seq 0 $(($NUM_DEVICES - 1))); do
      ${pkgs.openrgb}/bin/openrgb --noautoconnect --device $i --mode static --color 000000
    done
  '';
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
    environment.systemPackages = [ cfg.package ];
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
          }";
        Restart = "always";
      };
    };
    systemd.services.no-rgb = {
      description = "OpenRGB no RGB";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${no-rgb}/bin/no-rgb";
        Type = "oneshot";
      };
    };
  };
}
