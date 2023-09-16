{ config, lib, mylib, ... }:

with lib;
let
  cfg = config.my.services.tailscale;
  inherit (mylib) mkDefaultTrueEnableOption;
in {
  options.my.services.tailscale = {
    enable = mkEnableOption "tailscale";
    authUrl = mkOption {
      type = types.str;
      default = "https://headscale.mado.moe";
    };
    useRoutingFeatures = mkOption {
      type = types.enum [ "none" "client" "server" "both" ];
      default = "none";
      example = "server";
    };
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      port = config.my.ports.tailscale.listen;
      inherit (cfg) useRoutingFeatures;
    };
  };
}
