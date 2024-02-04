{ lib, ... }:

with lib; {
  options = {
    my.ids.uids = mkOption {
      default = { };
      type = types.attrs;
    };
  };

  config.my.ids.uids = {
    sinkerine = 1000;
    traefik = 198;
    nix-serve = 199;
    dockremap = 100000;
    smtp-secret = 2000;
    nut = 84;
    nut-exporter = 2001;
  };
}
