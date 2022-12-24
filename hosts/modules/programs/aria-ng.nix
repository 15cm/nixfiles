{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.programs.AriaNg;
in {
  options.my.programs.AriaNg = {
    enable = mkEnableOption "AriaNg";
    port = mkOption {
      type = types.int;
      default = 3001;
    };
  };

  config = mkIf cfg.enable {
    services.nginx.enable = true;
    services.nginx.virtualHosts."AriaNg" = {
      root = "${pkgs.AriaNg}/share/AriaNg";
      listen = [{
        addr = "localhost";
        port = cfg.port;
      }];
    };
  };
}
