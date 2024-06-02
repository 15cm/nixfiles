{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.cliphist;
in {
  options.my.services.cliphist = {
    enable = mkEnableOption "cliphist";
    wofiImgScript = mkOption {
      type = types.path;
      default = (builtins.fetchTree {
        type = "file";
        url =
          "https://raw.githubusercontent.com/sentriz/cliphist/cc3f40550e5e528b938927123e21b0128abe4e0a/contrib/cliphist-wofi-img";
        narHash = "sha256-uH1wV0qEv8JEJIfCnFZM3CxRcmtL8ZkIWuyOGoh+GJ0=";
      });
    };
  };

  config = mkIf cfg.enable { services.cliphist.enable = true; };
}
