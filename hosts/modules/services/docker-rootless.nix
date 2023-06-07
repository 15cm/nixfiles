{ config, lib, ... }:

with lib;

let cfg = config.my.services.docker-rootless;
in {
  options.my.services.docker-rootless = {
    enable = mkEnableOption "docker rootless";
  };

  config = mkIf cfg.enable
    (mkMerge [{ virtualisation.docker.rootless = { enable = true; }; }]);
}
