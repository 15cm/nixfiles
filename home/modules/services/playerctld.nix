{ config, lib, ... }:

with lib;
let cfg = config.my.services.playerctld;
in {
  options.my.services.playerctld = { enable = mkEnableOption "Playerctld"; };

  config = mkIf cfg.enable {
    home.packages = [ config.services.playerctld.package ];
    services.playerctld.enable = true;
  };
}
