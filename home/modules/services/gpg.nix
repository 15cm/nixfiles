{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.gpg;
in {
  options.my.services.gpg = { enable = mkEnableOption "gpg"; };

  config = mkIf cfg.enable {
    programs.gpg.enable = true;
    services.gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-qt;
    };
  };
}
