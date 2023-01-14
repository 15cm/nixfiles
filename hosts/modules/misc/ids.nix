{ lib, ... }:

with lib; {
  options = {
    my.ids.uids = mkOption {
      default = { };
      type = types.attrs;
    };
    my.ids.hostIds = mkOption {
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
  };

  config.my.ids.hostIds = {
    kazuki = "9bf23bea";
    asako = "4d3e143f";
    sachi = "0848402f";
    amane = "a9bce3f8";
    yumiko = "b360de3a";
  };
}
